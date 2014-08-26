module OSX
  class ACL
    class Assignment
      attr_accessor :type, :uuid, :name, :id

      def initialize(components)
        @type, @uuid, @name, @id = components
      end

      def orphan?
        name.to_s == ""
      end

    end
  end
end
