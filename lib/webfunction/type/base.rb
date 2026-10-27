# frozen_string_literal: true

module WebFunction
  module Type
    class Base
      attr_reader :base_type, :refinement

      # The type argument when this is a generic object applied to a type: <tt>{ "object.list" => "object.user" }</tt>
      # is +object.list+ with the argument +object.user+. +nil+ for any other type.
      attr_reader :arg

      def initialize(base_type:, refinement: nil, arg: nil)
        @base_type = base_type
        @refinement = refinement
        @arg = arg
      end

      def inspect
        text = @refinement ? "#<#{@base_type} #{@refinement}" : "#<#{@base_type}"
        @arg ? "#{text} of #{@arg.inspect}>" : "#{text}>"
      end

      def format(format = :default)
        case format
        when :compact
          @refinement || @base_type
        when :base
          @base_type
        when :default
          text = @refinement ? "#{@base_type}.#{@refinement}" : @base_type
          @arg ? "#{text}<#{@arg.format(format)}>" : text
        else
          raise ArgumentError, "unknown format: #{format.inspect}"
        end
      end

      def to_s
        format(:default)
      end

      def ==(other)
        other.is_a?(Base) && other.base_type == @base_type && other.refinement == @refinement && other.arg == @arg
      end
      alias eql? ==

      def hash
        [Base, @base_type, @refinement, @arg].hash
      end

      def objects
        own = @base_type == "object" && @refinement ? [@refinement] : []

        (own + (@arg ? @arg.objects : [])).uniq
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