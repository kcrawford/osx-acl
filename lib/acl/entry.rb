require 'acl/assignment'
module OSX
  class ACL
    class Entry
      attr_accessor :text

      def self.from_text(text)
        new.tap {|entry| entry.text = text }
      end

      def orphaned?
        assignment.orphan?
      end

      def assignment
        ACL::Assignment.new(assignment_components)
      end

      def components
        text.split(":")
      end

      def assignment_components
        components[0..-3]
      end

      def permissions
        components.last.split(",")
      end

      def rule
        components[-2]
      end
    end
  end
end
