# frozen_string_literal: true

module WebFunction
  module Type
    class ArrayOf
      attr_reader :base_type, :of

      def initialize(of)
        @base_type = "array"
        @of = of
      end

      def refinement
        nil
      end

      def inspect
        "#<ArrayOf #{@of.inspect}>"
      end

      def format(format = :default)
        case format
        when :base
          "array"
        when :compact, :default
          "array<#{@of.format(format)}>"
        else
          raise ArgumentError, "unknown format: #{format.inspect}"
        end
      end

      def to_s
        format(:default)
      end

      def ==(other)
        other.is_a?(ArrayOf) && other.of == @of
      end
      alias eql? ==

      def hash
        [ArrayOf, @of].hash
      end

      def objects
        @of.objects
      end

      def without_refinements
        ArrayOf.new(@of.without_refinements)
      end

      def valid?(value)
        value.is_a?(Array) && value.all? { |element| @of.valid?(element) }
      end
    end
  end
end
