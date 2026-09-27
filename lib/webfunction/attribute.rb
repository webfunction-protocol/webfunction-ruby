# frozen_string_literal: true

module WebFunction
  # Attributes define output fields that may be produced and returned by a Web Function {Endpoint} when the type of the 
  # return is `object`.
  #
  # See the [attributes section][0] on the Web Function website for more details about attribute definitions, 
  # recognized keys, and usage.
  #
  # [0]: https://webfunction.org/package#attributes
  #
  class Attribute
    include Flaggable

    def initialize(name:, type:, values: [], flags: [], docs: nil)
      @name = name
      @type = Type.parse(type)
      @values = values
      @flags = flags
      @docs = docs.to_s
    end

    class << self
      # Creates a new Attribute from a hash. Typically coming from a {Package}.
      #
      # @param attribute [Hash] The attribute hash
      #
      # @return [Attribute] A new Attribute instance
      #
      def from_hash(attribute)
        unless attribute.is_a?(Hash)
          return
        end

        unless attribute["name"]
          return
        end

        unless attribute["type"]
          return
        end

        new(
          name: attribute["name"],
          type: attribute["type"],
          values: [*attribute["values"]],
          flags: Utils.normalize_array_of_strings(attribute["flags"]),
          docs: attribute["docs"],
        )
      end

      # Creates a new Attribute from an array of hashes. Typically coming from a {Package}. Uses {Attribute#from_hash}
      # under the hood.
      #
      # @param attributes [Array<Hash>] The attribute array of hashes
      #
      # @return [Array<Attribute>] A new array of Attribute instances
      #
      def from_array(attributes)
        Utils.normalize_array attributes do |attribute|
          from_hash(attribute)
        end
      end
    end

    # The name of the attribute as it will appear in the endpoint's output
    # object.
    #
    # This is required for the argument to be valid.
    #
    # @return [String]
    #
    attr_reader :name

    # The type of value returned for this attribute. Must be one of:
    #
    # - object
    # - array
    # - string
    # - number
    # - boolean
    #
    # This is required for the argument to be valid.
    #
    # @return [String]
    #
    attr_reader :type

    # An array specifying the exact, case-sensitive values that may be returned for this attribute. Each value in the 
    # values array must conform to the data type specified in the "type" key.
    #
    # This is useful for attributes that can only take a select set of values (enums or constants).
    #
    # @return [Array]
    #
    attr_reader :values

    # A markdown string describing this attribute and its purpose in the output object. Used by documentation tools, 
    # and highly recommended.
    #
    # @return [String]
    #
    attr_reader :docs

    # Whether the attribute can be null.
    #
    # @return [Boolean]
    #
    def nullable?
      flag?("nullable")
    end
  end
end
