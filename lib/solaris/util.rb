module Solaris

  # Utility module.
  module Util

    require 'rubygems'
    gem 'mechanize', '>= 1.0.0'
    require 'mechanize'

    # Download the given URL, return the document body. Options:
    #   :agent -- set HTTP user agent
    #   :password -- Oracle support password
    #   :to_file -- a file path to which the patch/readme should be saved
    #   :to_dir -- a directory path to which the patch/readme should be saved
    #   :user -- Oracle support username
    # (:to_dir and :to_file are mutually exclusive)
    def Util.download!(url, opts={})
      agent = Mechanize.new
      dirname, filename = nil, nil
      opts.each do |key, value|
        case key
        when :agent
          agent.user_agent = value
        when :to_dir
          dirname = value
        when :to_file
          filename = value
        when :password, :user
          # noop
        else
          raise ArgumentError, "Unknown option key #{key.inspect}"
        end
      end
      # If we got a filename then open now before attempting download
      raise ArgumentError, 'Cannot specify both :to_dir and :to_file' if filename && dirname
      filename = File.join(dirname, File.basename(url)) if dirname
      begin
        file = File.open(filename, 'w') if filename
        # Set agent authentication parameters
        if opts[:user] && opts[:password]
          agent.basic_auth(opts[:user], opts[:password])
        elsif opts[:user]
          raise ArgumentError, 'Cannot authenticate without a password'
        elsif opts[:password]
          raise ArgumentError, 'Cannot authenticate without a username'
        end
        # Download file and save as required
        page = agent.get(url)
        if file
          file.write(page.body)
          file.close
        end
      rescue => exception
        # Try to remove incomplete file on error
        if file
          begin file.close ; rescue ; end
          begin File.unlink(file) ; rescue ; end
        end
        raise exception # rethrow original exception
      end
      page.body # return file as string (even if written)
    end

  end # Util

end # Solaris
