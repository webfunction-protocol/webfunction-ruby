# frozen_string_literal: true

module WebFunction
  module Type
    class Any
      # The MALFORMED_* reason (see {Type}) when this stands in for an invalid generic application, otherwise +nil+.
      attr_reader :malformed

      def initialize(param: false, malformed: nil)
        @param = param
        @malformed = malformed
      end

      # Whether this is the generic type parameter +T+.
      def param?
        @param
      end

      def base_type
        "any"
      end

      def refinement
        nil
      end

      def inspect
        "#<any>"
      end

      def format(_format = :default)
        "any"
      end

      def to_s
        format(:default)
      end

      def ==(other)
        other.is_a?(Any)
      end
      alias eql? ==

      def hash
        Any.hash
      end

      def objects
        []
      end

      def without_refinements
        self
      end

      def valid?(_value)
        true
      end
    end
  end
end