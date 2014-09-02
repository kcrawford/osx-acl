require "acl/version"
require "acl/entry"
require 'open3'

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
      begin
        file_descriptor = File.open(path, "r")
      rescue Errno::ENOENT
        file_descriptor = false
        return []
      end
      acl_ptr = api.acl_get_fd(file_descriptor.fileno)
      acl_text_ptr = api.acl_to_text(acl_ptr, nil)
      return [] if acl_text_ptr.null?
      ace_lines = acl_text_ptr.read_string.split("\n")[1..-1]
      ace_lines
    ensure
      api.acl_free(acl_text_ptr)
      api.acl_free(acl_ptr)
      file_descriptor.close if file_descriptor
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

    def file_flags
      flags = ""
      Open3.popen3("stat", "-f", "%f", path) do |stdin,stdout,stderr,thread|
        flags = stdout.read
      end
      flags.to_i.to_s(8)
    end

    def preserving_flags
      original_file_flags = file_flags
      if original_file_flags == "0"
        yield
      else
        begin
          system("chflags", "0", path)
          yield
        ensure
          system("chflags", original_file_flags, path)
        end
      end
    end

    def remove_entry_at_index(index)
      args = ["chmod", "-a#", index.to_s, path]
      puts args.join(" ")
      if ENV['OSX_ACL_NOOP'] == "yes"
        true
      else
        preserving_flags do
          system(*args)
        end
      end
    end

    def api
      API
    end

  end

end
