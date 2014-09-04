require 'acl/assignment'
module OSX
  class ACL
    class Entry
      attr_accessor :components

      def self.from_text(text)
        new.tap {|entry| entry.components = text.split(":") }
      end

      def to_s
        text
      end

      def inherited=(should_inherit)
        if should_inherit && !inherited?
          rules << "inherited"
        elsif inherited? &! should_inherit
          rules.delete("inherited")
        end
      end

      def inherited?
        rules.include? "inherited"
      end

      def orphaned?
        assignment.orphan?
      end

      def assignment
        ACL::Assignment.new(assignment_components)
      end

      def assignment_components
        components[0..-3]
      end

      def permissions
        components.last.split(",")
      end

      def rules
        components[-2]
      end
    end
  end
end
