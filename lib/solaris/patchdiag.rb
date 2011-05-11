
module Solaris

  # Class to represent the Oracle patchdiag "database" (file).
  # See the following Oracle support publication for format:
  # https://support.oracle.com/CSP/main/article?cmd=show&type=NOT&doctype=REFERENCE&id=1019527.1
  class Patchdiag

    require 'date'

    require 'solaris/exception'
    require 'solaris/patchdiag_entry'
    require 'solaris/util'

    # Default patchdiag.xref file, as for Patch Check Advanced cache
    DEFAULT_XREF_FILE = '/var/tmp/patchdiag.xref'

    # URL of latest patchdiag.xref from Oracle.
    DEFAULT_XREF_URL = 'https://getupdates.oracle.com/reports/patchdiag.xref'

    # An array containing all entries (of class PatchdiagEntry) read
    # from the patchdiag.xref file.
    attr_accessor :entries

    # Create a new patchdiag database object by reading the given
    # xref file (this may be a filename (string) or a fileish object
    # (File, StringIO)). If no xref file is given then the default
    # is read (/var/tmp/patchdiag.xref); this is the cache file used
    # by Patch Check Advanced (pca).
    def initialize(xref_file=DEFAULT_XREF_FILE)
      xref_file = File.new( xref_file ) if xref_file.is_a?(String)
      @entries = xref_file.
        readlines.
        reject { |line| line =~ /^#|^\s*$/ }. # discard comments, blanks
        map { |line| PatchdiagEntry.new( line ) }
    end

    # Download the patchdiag database and return it as a string.
    # Note the contents will be returned as a string but not saved
    # to disk unless :to_file or :to_dir are given.
    # For the options hash argument see Solaris::Util.download!
    def Patchdiag.download!(opts={})
      url = opts.delete( :url ) || DEFAULT_XREF_URL
      Util.download!( url, opts )
    end

    # Open the given optional patchdiag xref file and yield to the
    # optional block.
    def Patchdiag.open(xref_file=DEFAULT_XREF_FILE, &blk)
      patchdiag = Patchdiag.new( xref_file )
      if block_given?
        yield patchdiag
      else
        patchdiag
      end
    end

    # Returns an array of Solaris::PatchdiagEntry from the
    # patchdiag.xref with the given patch number (a String like
    # xxxxxx-yy or xxxxxx or a Solaris::Patch), sorted by minor number.
    # If both a major and minor number are supplied (xxxxxx-yy) then
    # returned entries (normally only one) will match exactly. If only
    # a major number (xxxxxx) is supplied then all entries with that
    # major number are returned. Returns an empty array if no such
    # patches can be found.
    def find(patch)
      patch = Patch.new( patch.to_s )
      property = patch.minor ? :to_s : :major
      comparator = patch.send( property )
      all.select { |pde| pde.patch.send( property ) == comparator }
    end

    # Return the Solaris::PatchdiagEntry of the latest version of the
    # given patch (a String like xxxxxx-yy or xxxxxx or a
    # Solaris::Patch). Throws Solaris::Patch::NotFound if the patch
    # cannot be found in patchdiag.xref.
    def latest(patch)
      major = Patch.new( patch.to_s ).major
      find( major ).max ||
        raise( Solaris::Patch::NotFound, "Cannot find patch #{patch} in patchdiag.xref" )
    end

    # Return the Solaris::PatchdiagEntry of the latest non-obsolete successor
    # of this patch.
    #
    # Throws Solaris::Patch::NotFound if the patch or any of its named
    # successors cannot be found in patchdiag.xref, or if no later version
    # of the patch exists.
    #
    # Throws Solaris::Patch::SuccessorLoop if the successor of a patch refers
    # to a patch that has already been referenced (an ancestor).
    #
    # The ancestors parameter is a recursion accumulator and should not normally
    # be assigned to by callers.
    def successor(patch, ancestors=[])
      patch = Patch.new( patch.to_s )
      raise Solaris::Patch::SuccessorLoop,
        "Loop detected for patch #{patch} with ancestors #{ancestors.inspect}" if ancestors.include?( patch )
      ancestors << patch
      if ! patch.minor # patch has no minor number
        successor( latest( patch ).patch, ancestors )
      elsif ! entry = find( patch ).last # explicit patch not found
        latest_patch = latest( patch ).patch
        raise Solaris::Patch::NotFound,
          "Patch #{patch} not found and has no later version" if latest_patch.minor <= patch.minor
        successor( latest_patch, ancestors )
      else
        if entry.obsolete?
          succ = entry.successor
          successor( succ, ancestors )
        elsif entry.bad?
          raise BadSuccessor, "Terminal successor #{patch} is bad/withdrawn"
        else
          entry
        end
      end
    end

    # Return all patchdiag entries (PatchdiagEntry) defined in the patchdiag.xref.
    # This method scans the entire patchdiag database so may be a little slow:
    # callers are encouraged to cache or memoize their results.
    def all(opts={})

      # Defaults
      order = :ascending
      sort_by = :patch

      # Parse options
      opts.each do |key, value|
        case key
        when :sort_by
          raise ArgumentError, "Invalid sort_by #{value.inspect}" unless [ :patch, :date ].include?( value )
          sort_by = value
        when :order
          raise ArgumentError, "Invalid order #{value.inspect}" unless [ :ascending, :descending ].include?( value )
          order = value
        else
          raise ArgumentError, "Unknown option key #{key.inspect}"
        end
      end

      # Compute the lambda for sorting.
      if order == :ascending
        boat_op = lambda { |x,y| x.send( sort_by ) <=> y.send( sort_by ) }
      else
        boat_op = lambda { |x,y| y.send( sort_by ) <=> x.send( sort_by ) }
      end

      # Sort and return.
      @entries.sort { |x,y| boat_op.call( x, y ) }

    end

  end # Patchdiag

end # Solaris

