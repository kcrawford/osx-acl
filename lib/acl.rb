require "acl/version"
require "acl/entry"
require 'open3'
require 'delegate'
require 'shellwords'

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

    attr_accessor :path, :entries

    def self.of(path)
      new.tap {|acl| acl.path = path }
    end

    def entries
      @entries ||= make_entries
    end

    def make_entries
      Entries.new(self, entry_lines.map {|line| ACL::Entry.from_text(line) })
    end

    class Entries < SimpleDelegator
      attr_reader :acl
      def initialize(acl, entries)
        @acl = acl
        super(entries)
      end
      def as_inherited
        map {|entry| entry.inherited = true }
      end

      def remove_if
        removal_count = 0
        # we reverse the order of the entries so we can remove entries without affecting the index of other entries
        reverse.each_with_index do |entry,index|
          if yield(entry)
            # since entries are reversed, we calculate the actual index
            actual_index = (length - 1) - index
            if acl.remove_entry_at_index(actual_index)
              removal_count += 1
            else
              raise "Failed to remove #{entry} from #{path}"
            end
          end
        end
        removal_count
      end
    end

    def entry_lines
      file_descriptor, acl_text_ptr, acl_ptr = nil
      begin
        file_descriptor = File.open(path, "r")
      rescue Errno::EOPNOTSUPP
        return []
      rescue Errno::ENOENT
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
      entries.remove_if {|entry| entry.orphaned? }
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

    # Wraps a file action
    #   first removes file flags that would cause the action to fail
    #   then yields to the block to perform the action
    #   then restores the flags
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
      puts "#{args[0]} #{args[1]} #{args[2]} #{Shellwords.escape(args[3])}"
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
