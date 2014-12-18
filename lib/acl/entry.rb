require 'acl/assignment'
module OSX
  class ACL
    class Entry
      include Comparable
      attr_accessor :components

      def self.from_text(text)
        new.tap {|entry| entry.components = text.split(":") }
      end

      def <=>(other)
        components <=> other.components
      end

      def to_s
        components.join(":")
      end

      def inherited=(should_inherit)
        if should_inherit && !inherited?
          rules << "inherited"
        elsif inherited? && !should_inherit
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
        components[-2].split(",")
      end
    end
  end
end
