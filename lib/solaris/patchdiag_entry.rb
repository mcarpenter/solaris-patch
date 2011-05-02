
module Solaris

  # Class to represent a line from Sun's patchdiag.xref patch "database".
  # See the following Oracle support publication for format:
  # https://support.oracle.com/CSP/main/article?cmd=show&type=NOT&doctype=REFERENCE&id=1019527.1
  class PatchdiagEntry

    include Comparable

    require 'date'

    require 'solaris/exception'
    require 'solaris/patch'

    # An array of architectures for this patch. Values are strings like
    # "sparc", "i386".
    attr_accessor :archs

    # The bad field from the patchdiag xref database. Should be either 'B'
    # or the empty string. See also PatchdiagEntry#bad?
    attr_accessor :bad

    # The date of this patch (a Date object).
    attr_accessor :date

    # The operating system for this patch, a string like "2.4, "10",
    # "10_x86" or "Unbundled".
    attr_accessor :os

    # The patch object (class Patch) that this entry represents. See
    # also convenience methods PatchdiagEntry#major and PatchdiagEntry#minor.
    attr_accessor :patch

    # An array of packages that pertain to this patch. Values are strings
    # like "SUNWcsr".
    attr_accessor :pkgs

    # The recommended field from the patchdiag xref database. Should be either 'R'
    # or the empty string. See also PatchdiagEntry#recommended?
    attr_accessor :recommended

    # The security field from the patchdiag xref database. Should be either 'S'
    # or the empty string. See also PatchdiagEntry#security?
    attr_accessor :security

    # This synopsis of this patch from the patchdiag xref database. This is a free
    # text field (string).
    attr_accessor :synopsis

    def initialize(patchdiag_line)
      fields = patchdiag_line.split('|')[0..10]
      major, minor, date, @recommended, @security, @obsolete, @bad, @os, archs, pkgs, @synopsis = *fields
      @archs = archs.split( ';' )
      if date == ''
        year, month, day = 1970, 1, 1
      else
        month_s, day_s, year_s = *date.split( '/' )
        year = ( year_s.to_i > 50 ? "19#{year_s}" : "20#{year_s}" ).to_i
        month = Date::ABBR_MONTHNAMES.index( month_s )
        day = day_s.to_i
      end
      @date = Date.new( year, month, day )
      @patch = Patch.new( major, minor )
      @pkgs = pkgs.split( ';' )
    end

    # Boolean, returns true if this patch is marked as "bad" in the patchdiag
    # xref database.
    def bad? ; @bad == 'B' end

    # Download this patch. For options hash see Patch#download!.
    def download_patch!(opts={}) ;
      @patch.download_patch!( opts )
    end

    # Download the README for this patch. For options hash see Patch#download!.
    def download_readme!(opts={})
      @patch.download_readme!( opts )
    end

    # Returns this entries major patch number as an integer.
    def major ; @patch.major end

    # Returns this entries minor patch number as an integer.
    def minor ; @patch.minor end

    # Boolean, returns true if this patch is marked as "obsolete" in the patchdiag
    # xref database.
    def obsolete? ; @obsolete == 'O' end

    # Boolean, returns true if this patch is marked as "recommended" in the patchdiag
    # xref database.
    def recommended? ; @recommended == 'R' end

    # Boolean, returns true if this patch is marked as "security" in the patchdiag
    # xref database.
    def security? ; @security == 'S' end

    # Return the Solaris::Patch by which this entry is obsoleted.
    # Throws Solaris::Patch::NotObsolete if this entry is not obsolete.
    # Throws Solaris::Patch::MultipleSuccessors if this entry has more than
    # one successor.
    # Throws Solaris::Patch::InvalidSuccessor if the "obsoleted by" entry cannot
    # be understood.
    def successor
      # I <3 consistency:
      # Obsoleted by : XXXXXX-XX
      # Obsoleted by: XXXXXX-XX
      # OBSOLETED by: XXXXXX
      # Obsoleted by: XXXXXX-XX OBSOLETED by WITHDRAWN
      # OBSOLETED by WITHDRAWN
      # OBSOLETED by XXXXXX
      # OBSOLETED by XXXXXX and XXXXXX # we ignore this pattern, see below
      # Obsoleted by XXXXXX-XX:
      # OBSOLETED by XXXXXX-XX:
      # WITHDRAWN Obsoleted by: XXXXXX-XX
      # WITHDRAWN PATCH Obsolete by:
      # WITHDRAWN PATCH Obsoleted by:
      # WITHDRAWN PATCH Obsoleted by XXXXXX-XX:

      # Fail if this entry is not actually obsolete
      raise Solaris::Patch::NotObsolete,
        "Entry #{patch.inspect} not obsolete" unless obsolete?

      # Fail on these two entries from 1999 since they are the only ones ever
      # that are succeeded by two patches each
      raise Solaris::Patch::MultipleSuccessors,
        "More than one successor for entry #{patch.inspect}" if [ 105716, 105717 ].include?( self.major )

      # See if we can find a successor
      if synopsis =~ /obsolete(d?) by\s*(:?)\s*(\d+(-\d+)?)/i
        Patch.new( $3 )
      else
        raise Solaris::Patch::InvalidSuccessor,
          "Failed to parse successor to obsolete patchdiag entry for patch #{patch.inspect}"
      end
    end

    # Output this patchdiag xref entry as a string, in format of Oracle's
    # database.
    def to_s
      [ patch.major,
        Patch.pad_minor( patch.minor ),
        date_s,
        @recommended,
        @security,
        @obsolete,
        @bad,
        @os,
        join_semis( @archs ),
        join_semis( @pkgs ),
        @synopsis
      ].join('|')
    end

    # Compare (by delegated comparison of patch versions, see Solaris::Patch#<=>).
    def <=>(other)
      self.patch <=> other.patch
    end

    private

    # Convert the Date object to a date string as found in patchdiag.xref.
    def date_s
      [ Date::ABBR_MONTHNAMES[ @date.mon ], # month eg Jan
        @date.mday.to_s.rjust(2, '0'), # day of month
        @date.year % 100 # 2 digit year
      ].join('/')
    end

    # Join an array of items with semicolons and append a trailing
    # semicolon if the array is non-empty, otherwise return the 
    # empty string. Used to format @archs and @pkgs for #to_s.
    def join_semis(a)
      a.empty? ? '' : a.join(';') + ';'
    end

  end # PatchdiagEntry

end # Solaris

