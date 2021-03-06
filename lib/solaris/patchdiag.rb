module Solaris

  # Class to represent the Oracle patchdiag "database" (file).
  # See the following Oracle support publication for format:
  # https://support.oracle.com/CSP/main/article?cmd=show&type=NOT&doctype=REFERENCE&id=1019527.1
  class Patchdiag

    require 'date'

    require 'solaris/exception'
    require 'solaris/patchdiag_entry'
    require 'solaris/util'

    include Enumerable

    # Default patchdiag.xref file, as for Patch Check Advanced cache
    DEFAULT_XREF_FILE = '/var/tmp/patchdiag.xref'

    # URL of latest patchdiag.xref from Oracle.
    DEFAULT_XREF_URL = 'https://getupdates.oracle.com/reports/patchdiag.xref'

    # The date of this patchdiag.xref, parsed from the header.
    attr_writer :date

    # The array of lines that comprise the header, sans trailing newline.
    attr_accessor :header

    # The array of lines that comprise the footer, sans trailing newline.
    attr_accessor :footer

    # Create a new patchdiag database object by reading the given
    # xref file (this may be a filename (string) or a fileish object
    # (File, StringIO)). If no xref file is given then the default
    # is read (/var/tmp/patchdiag.xref); this is the cache file used
    # by Patch Check Advanced (pca).
    def initialize(xref_file=DEFAULT_XREF_FILE)
      xref_file = File.new(xref_file) if xref_file.is_a?(String)
      @entries, @header, @footer = [], [], []
      xref_file.each_line do |line|
        if line =~ /^\d/
          @entries << PatchdiagEntry.new(line)
        else
          (@entries.empty? ? @header : @footer) << line.chomp
        end
      end
    end

    # Download the patchdiag database and return it as a string.
    # Note the contents will be returned as a string but not saved
    # to disk unless :to_file or :to_dir are given.
    # For the options hash argument see Solaris::Util.download!
    def Patchdiag.download!(opts={})
      url = opts.delete(:url) || DEFAULT_XREF_URL
      Util.download!(url, opts)
    end

    # Open the given optional patchdiag xref file and yield to the
    # optional block.
    def Patchdiag.open(xref_file=DEFAULT_XREF_FILE, &blk)
      patchdiag = Patchdiag.new(xref_file)
      if block_given?
        yield patchdiag
      else
        patchdiag
      end
    end

    # Create and return a deep copy of this object.
    def clone
      Marshal.load(Marshal.dump(self))
    end

    # Return the date parsed from the patchdiag.xref comment lines.
    def date
      ## PATCHDIAG TOOL CROSS-REFERENCE FILE AS OF Jan/23/14 ##
      @date ||= @header.find { |line| line =~ /\s(\w\w\w\/\d\d\/\d\d)\s/ } &&
        Date.parse($1)
    end

    # For Enumerator module: yields each Solaris::PatchdiagEntry in
    # turn.
    def each(&blk)
      @entries.each(&blk)
    end

    # Returns an array of Solaris::PatchdiagEntry from the
    # patchdiag.xref with the given patch number (a String like
    # xxxxxx-yy or xxxxxx or a Solaris::Patch), sorted by minor number.
    # If both a major and minor number are supplied (xxxxxx-yy) then
    # returned entries (normally only one) will match exactly. If only
    # a major number (xxxxxx) is supplied then all entries with that
    # major number are returned. Returns an empty array if no such
    # patches can be found. This method overrides Enumerable#find.
    def find(patch)
      patch = Patch.new(patch.to_s)
      property = patch.minor ? :to_s : :major
      comparator = patch.send(property)
      @entries.select { |pde| pde.patch.send(property) == comparator }
    end

    # Strangely Enumerable module does not define Enumerable#last (although
    # it does define Enumerable#first) so we define last here.
    def last
      @entries.last
    end

    # Return the Solaris::PatchdiagEntry of the latest version of the
    # given patch (a String like xxxxxx-yy or xxxxxx or a
    # Solaris::Patch). Throws Solaris::Patch::NotFound if the patch
    # cannot be found in patchdiag.xref.
    def latest(patch)
      major = Patch.new(patch.to_s).major
      find(major).max ||
        raise(Solaris::Patch::NotFound,
              "Cannot find patch #{patch} in patchdiag.xref")
    end

    # Returns a (deep) copy of +self+ with the entries sorted, takes an
    # optional block. This method overrides Enumerable#sort. See also
    # Solaris::Patchdiag#sort!.
    def sort(&blk)
      clone.sort!(&blk)
    end

    # Returns +self+ with the entries sorted in place, takes an optional
    # block. See also Solaris::Patchdiag#sort.
    def sort!(&blk)
      # use @entries since #entries returns a copy
      @entries.sort!(&blk)
      self
    end

    # Return an array of Solaris::Patch of the successors to the given
    # patch terminating in the latest non-obsolete successor (where that
    # exists).
    #
    # Throws Solaris::Patch::NotFound if the patch or any of its named
    # successors cannot be found in patchdiag.xref, or if no later version
    # of the patch exists.
    #
    # Throws Solaris::Patch::SuccessorLoop if the successor of a patch refers
    # to a patch that has already been referenced (an ancestor).
    #
    # The ancestors parameter is a recursion accumulator and should not
    # normally be assigned to by callers.
    def successors(patch, ancestors=[])
      patch = Patch.new(patch.to_s)
      raise Solaris::Patch::SuccessorLoop,
        "Loop detected for patch #{patch} with ancestors #{ancestors.inspect}" if ancestors.include?(patch)
      ancestors << patch
      if ! patch.minor # patch has no minor number
        successors(latest(patch).patch, ancestors)
      elsif ! entry = find(patch).last # explicit patch not found
        latest_patch = latest(patch).patch
        raise Solaris::Patch::NotFound,
          "Patch #{patch} not found and has no later version" if latest_patch.minor <= patch.minor
        successors(latest_patch, ancestors)
      else
        if entry.obsolete?
          succ = entry.successor
          successors(succ, ancestors)
        elsif entry.bad?
          raise BadSuccessor, "Terminal successor #{patch} is bad/withdrawn"
        else
          ancestors
        end
      end
    end

    # Return the Solaris::PatchdiagEntry of the latest non-obsolete successor
    # of this patch. This is a convenience method for #successors.last.
    def successor(patch)
      latest(successors(patch).last)
    end

    # Returns a string representation of the patchdiag.xref. All comments
    # and blank lines are elided.
    def to_s
      (@header + @entries + @footer).join("\n") << "\n"
    end
    alias to_str to_s

  end # Patchdiag

end # Solaris
