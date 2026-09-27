# frozen_string_literal: true

module WebFunction
  module Type
    class Union
      attr_reader :members

      def initialize(members)
        @members = members
      end

      def base_type
        nil
      end

      def refinement
        nil
      end

      def inspect
        "#<Union #{@members.map(&:inspect).join(" | ")}>"
      end

      def format(format = :default)
        @members.map { |member| member.format(format) }.join(" | ")
      end

      def to_s
        format(:default)
      end

      def ==(other)
        other.is_a?(Union) && other.members == @members
      end
      alias eql? ==

      def hash
        [Union, @members].hash
      end

      def objects
        @members.flat_map(&:objects).uniq
      end

      def without_refinements
        Type.union(@members.map(&:without_refinements))
      end

      def valid?(value)
        @members.any? { |member| member.valid?(value) }
      end
    end
  end
end
