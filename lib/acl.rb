require "acl/version"
require "acl/entry"

module OSX

  require 'ffi'
  module API
    extend FFI::Library
    ffi_lib FFI::Library::LIBC
    attach_function :acl_get_fd, [:int], :pointer
    attach_function :acl_to_text, [:pointer, :pointer], :pointer
    attach_function :acl_valid, [:pointer], :int
    attach_function :acl_free, [:pointer], :int
  end

  class ACL

    attr_accessor :path

    def self.of(path)
      new.tap {|acl| acl.path = path }
    end

    def entries
      entry_lines.map {|line| ACL::Entry.from_text(line) }
    end

    def entry_lines
      file_descriptor = File.open(path, "r")
      acl_ptr = api.acl_get_fd(file_descriptor.fileno)
      acl_text_ptr = api.acl_to_text(acl_ptr, nil)
      return [] if acl_text_ptr.null?
      ace_lines = acl_text_ptr.read_string.split("\n")[1..-1]
      ace_lines
    ensure
      api.acl_free(acl_text_ptr)
      api.acl_free(acl_ptr)
      file_descriptor.close
    end

    def remove_orphans!
      removal_count = 0
      current_entries = entries
      current_entries.reverse.each_with_index do |entry,index|
        # since entries are reversed, we calculate the actual index
        actual_index = (current_entries.length - 1) - index
        if entry.orphaned?
          puts "removing #{entry} from #{path} at index #{actual_index}"
          if remove_entry_at_index(actual_index)
            removal_count += 1
          else
            raise "Failed to remove #{entry} from #{path}"
          end
        end
      end
      removal_count
    end

    def orphans
      entries.select {|e| e.orphaned? }
    end

    def remove_entry_at_index(index)
      args = ["chmod", "-a#", index.to_s, path]
      puts args.join(" ")
      if ENV['OSX_ACL_NOOP'] == "yes"
        true
      else
        system(*args)
      end
    end

    def api
      API
    end

  end

end
