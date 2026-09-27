# frozen_string_literal: true

require "ipaddr"
require "uri"

require_relative "type/base"
require_relative "type/array_of"
require_relative "type/union"
require_relative "type/any"

module WebFunction
  module Type
    ALLOWED_REFINEMENTS = {
      "number" => %w[u32 u64 i32 i64 f32 f64 timestamp].freeze,
      "string" => %w[date time datetime uuid base64 email phone url uri ipv4 ipv6 hostname].freeze,
    }.freeze

    # Value-level validators for each refinement, keyed by refinement name. Refinement names are unique across base
    # types, so a flat table is enough. Must stay in sync with {ALLOWED_REFINEMENTS}.
    REFINEMENT_VALIDATORS = {
      "u32" => ->(v) { v.is_a?(Integer) && v.between?(0, 0xFFFFFFFF) },
      "u64" => ->(v) { v.is_a?(Integer) && v.between?(0, 0xFFFFFFFFFFFFFFFF) },
      "i32" => ->(v) { v.is_a?(Integer) && v.between?(-0x80000000, 0x7FFFFFFF) },
      "i64" => ->(v) { v.is_a?(Integer) && v.between?(-0x8000000000000000, 0x7FFFFFFFFFFFFFFF) },
      "f32" => ->(v) { v.is_a?(Numeric) && v.to_f.finite? && v.to_f.abs <= 3.4028235e38 },
      "f64" => ->(v) { v.is_a?(Numeric) && v.to_f.finite? },
      "timestamp" => ->(v) { v.is_a?(Integer) && v >= 0 },
      "date" => ->(v) { v.match?(/\A\d{4}-\d{2}-\d{2}\z/) },
      "time" => ->(v) { v.match?(/\A\d{2}:\d{2}:\d{2}(\.\d+)?\z/) },
      "datetime" => ->(v) { v.match?(/\A\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?\z/) },
      "uuid" => ->(v) { v.match?(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/) },
      "base64" => ->(v) { (v.length % 4).zero? && v.match?(%r{\A[A-Za-z0-9+/]*={0,2}\z}) },
      "email" => ->(v) { v.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/) },
      "phone" => ->(v) { v.match?(/\A\+[1-9]\d{1,14}\z/) },
      "url" => ->(v) { (uri = URI.parse(v)).is_a?(URI::HTTP) && !uri.host.nil? rescue false },
      "uri" => ->(v) { !URI.parse(v).scheme.nil? rescue false },
      "ipv4" => ->(v) { IPAddr.new(v).ipv4? rescue false },
      "ipv6" => ->(v) { IPAddr.new(v).ipv6? rescue false },
      "hostname" => lambda do |v|
        v.match?(%r{\A(?=.{1,253}\z)([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\z})
      end,
    }.freeze

    def self.parse(raw)
      types = [*raw].map { |type| Type.detect(type) }.compact

      if types.empty?
        return Type.any
      end

      Type.union(types)
    end

    def self.detect(raw)
      case raw
      when String
        Type.base(raw)
      when Array
        types = raw.map { |type| Type.detect(type) }.compact

        if types.empty?
          return Type.array(Type.any)
        end

        Type.array(Type.union(types))
      else
        return nil
      end
    end

    def self.base(type)
      base_type, refinement = type.split(".", 2)

      case base_type
      when "string"
        if refinement && !ALLOWED_REFINEMENTS["string"].include?(refinement)
          return Type.string
        end

        Type.string(refinement)
      when "number"
        if refinement && !ALLOWED_REFINEMENTS["number"].include?(refinement)
          return Type.number
        end

        Type.number(refinement)
      when "object"
        Type.object(refinement)
      when "array"
        Type.array
      when "boolean"
        Type.boolean
      when "null"
        Type.null
      when "any"
        Type.any
      else
        nil
      end
    end

    def self.string(refinement = nil)
      Base.new(base_type: "string", refinement: refinement)
    end

    def self.number(refinement = nil)
      Base.new(base_type: "number", refinement: refinement)
    end

    def self.object(refinement = nil)
      Base.new(base_type: "object", refinement: refinement)
    end

    def self.array(of = any)
      ArrayOf.new(of)
    end

    def self.boolean
      Base.new(base_type: "boolean")
    end

    def self.null
      Base.new(base_type: "null")
    end

    def self.union(types)
      types = types.uniq

      if types.length > 1
        Union.new(types)
      else
        types.first
      end
    end

    def self.any
      Any.new
    end
  end
end
