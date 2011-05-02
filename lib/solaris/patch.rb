
module Solaris

  # Class to represent a patch number.
  class Patch

    include Comparable

    require 'solaris/util'
    require 'solaris/exception'
    require 'solaris/patchdiag'
    require 'solaris/patchdiag_entry'

    # Hash of URL patterns for downloads of type :patch or :readme.
    # The string format parameter (%s) is the full patch number.
    URL = {
      :patch => 'https://getupdates.oracle.com/all_unsigned/%s.zip',
      :readme => 'https://getupdates.oracle.com/readme/README.%s'
    }
    
    # The major number of the patch (integer), the part before the dash.
    attr_accessor :major

    # The minor number of the patch (integer), the part after the dash.
    # Since this is an integer, values less than 10 will not be left
    # padded with zero (see Patch::pad_minor). May be nil if not specified
    # in the constructor.
    attr_accessor :minor

    # Create a patch. May take zero, one or two parameters.
    #
    # In the one parameter form, this is a string of the patch number
    # eg '123456-78'.  (If you specify integer 123456-78 then the
    # resulting object will have major number 123378 and no minor
    # number; this is probably not what you want).
    #
    # In the two parameter form, the first parameter is the major
    # patch number (123456) and the second is the minor number (78).
    # Although it is possible to provide strings or integers here strings
    # should be prefered since a leading zero on an integer in Ruby
    # indicates an octal representation (in the tradition of C). This can
    # cause problems with a revision number of 09, since this is not a
    # valid octal representation.
    #
    # TLDR: Patch.new('123456-78')
    def initialize(major=nil, minor=nil)
      if major
        patch_no = major.to_s + ( minor ? "-#{minor}" : '' )
        if patch_no =~ /^(\d+)(-(\d+))?$/
          @major = $1.to_i
          @minor = $3.to_i if $3
        else
          raise ArgumentError, "Invalid patch number string #{patch_no.inspect}"
        end
      end
    end

    # Download this patch. For the options hash see private method Patch#download!
    def download_patch!(opts={})
      download!( :patch, opts )
    end

    # Download this README. For the options hash see private method Patch#download!
    def download_readme!(opts={})
      download!( :readme, opts )
    end

    # Return a string representation of this patch. If the minor
    # number has not been set then just return the major number.
    def to_s
      minor ? "#{@major}-#{Patch.pad_minor( @minor )}" : "#{@major}"
    end

    # Compare patch versions. (Performs a string compare on the full patch numbers).
    def <=>(other)
      self.to_s <=> other.to_s
    end

    # Download the given patch (this may be a Patch object or a string
    # like '123456-78'). For the options hash see Patch#download!.
    def Patch.download_patch!(patch, opts={})
      patch_to_dl = Patch.new( patch.to_s )
      patch_to_dl.download_patch!( opts )
    end

    # Download the given readme (this may be a Patch object or a string
    # like '123456-78'). For the options hash see Patch#download!.
    def Patch.download_readme!(patch, opts={})
      patch_to_dl = Patch.new( patch.to_s )
      patch_to_dl.download_readme!( opts )
    end

    # Left pad a minor version number with zeros as required.
    def Patch.pad_minor(minor)
      "#{minor.to_s.rjust( 2, '0' )}"
    end

    private

    # Download this patch or readme from Oracle.
    # For the options hash argument see Solaris::Util.download!
    def download!(type, opts={})
      raise ArgumentError, "Patch #{self.inspect} requires a major number to download" unless @major
      raise ArgumentError, "Patch #{self.inspect} requires a minor number to download" unless @minor
      raise ArgumentError, "Unknown type #{type.inspect}" unless URL[ type ]
      url = URL[ type ] % self.to_s
      opts = {
        :agent => 'Wget/1.10.2', # default user agent, required by Oracle
      }.merge( opts )
      Solaris::Util.download!( url, opts )
    end
      
  end # Patch

end # Solaris

