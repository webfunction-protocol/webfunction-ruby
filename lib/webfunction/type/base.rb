# frozen_string_literal: true

module WebFunction
  module Type
    class Base
      attr_reader :base_type, :refinement

      def initialize(base_type:, refinement: nil)
        @base_type = base_type
        @refinement = refinement
      end

      def inspect
        if @refinement
          "#<#{@base_type} #{@refinement}>"
        else
          "#<#{@base_type}>"
        end
      end

      def format(format = :default)
        case format
        when :compact
          @refinement || @base_type
        when :base
          @base_type
        when :default
          if @refinement
            "#{@base_type}.#{@refinement}"
          else
            @base_type
          end
        else
          raise ArgumentError, "unknown format: #{format.inspect}"
        end
      end

      def to_s
        format(:default)
      end

      def ==(other)
        other.is_a?(Base) && other.base_type == @base_type && other.refinement == @refinement
      end
      alias eql? ==

      def hash
        [Base, @base_type, @refinement].hash
      end

      def objects
        if @base_type == "object" && @refinement
          [@refinement]
        else
          []
        end
      end

      def without_refinements
        return self if @refinement.nil?

        Base.new(base_type: @base_type)
      end

      def valid?(value)
        case @base_type
        when "string"
          value.is_a?(String) && refinement_valid?(value)
        when "number"
          value.is_a?(Numeric) && !value.is_a?(Complex) && refinement_valid?(value)
        when "object"
          value.is_a?(Hash)
        when "boolean"
          value == true || value == false
        when "null"
          value.nil?
        else
          false
        end
      end

      private

      def refinement_valid?(value)
        @refinement.nil? || REFINEMENT_VALIDATORS.fetch(@refinement).call(value)
      end
    end
  end
end
