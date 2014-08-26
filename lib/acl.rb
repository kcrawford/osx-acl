require "acl/version"
require "acl/entry"

module OSX

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

    def api
      ACL::API
    end

  end

  require 'ffi'
  module API
    extend FFI::Library
    ffi_lib FFI::Library::LIBC
    attach_function :acl_get_fd, [:int], :pointer
    attach_function :acl_to_text, [:pointer, :pointer], :pointer
    attach_function :acl_valid, [:pointer], :int
    attach_function :acl_free, [:pointer], :int
  end
end
