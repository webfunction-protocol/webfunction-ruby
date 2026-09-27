# frozen_string_literal: true

module WebFunction
  # Represents a named object definition as described in a Web Function package.
  #
  # Objects are declared in a package under the `"objects"` key and can be referenced as a refined object type
  # (`object.<name>`) anywhere a type is expected. An `object.` reference appears in one of two contexts, which
  # determines which set of properties applies:
  #
  # - Argument context — the object is referenced as an argument's `type`. Its {#arguments} describe its properties.
  # - Attribute context — the object is referenced as an endpoint's `returns` or as an attribute's `type`. Its
  #   {#attributes} describe its properties.
  #
  # Because an object MAY be referenced in both contexts within the same package, it MAY define both `arguments` and
  # `attributes`; each set is used only in its matching context.
  #
  # It is named `ObjectSchema` rather than `Object` to avoid clashing with Ruby's built-in `::Object`.
  #
  # See the [object definition documentation][0] on the Web Function website for more details.
  #
  # [0]: https://webfunction.org/package#object-definition
  #
  class ObjectSchema
    # The contexts in which an object may be referenced. Each maps to the member set that applies in that context.
    #
    # @return [Array<Symbol>]
    #
    CONTEXTS = %i[arguments attributes].freeze

    def initialize(name:, arguments: [], attributes: [])
      @name = name
      @arguments = arguments.to_h { |a| [a.name, a] }
      @attributes = attributes.to_h { |a| [a.name, a] }
    end

    class << self
      # Creates a new ObjectSchema from a hash. Typically coming from a {Package}.
      #
      # @param object [Hash] The object hash
      #
      # @return [ObjectSchema, nil] A new ObjectSchema instance, or `nil` if the hash is invalid.
      #
      def from_hash(object)
        unless object.is_a?(Hash)
          return
        end

        unless object["name"]
          return
        end

        new(
          name: object["name"],
          arguments: Argument.from_array(object["arguments"]),
          attributes: Attribute.from_array(object["attributes"]),
        )
      end

      # Creates a new ObjectSchema from an array of hashes. Typically coming from a {Package}. Uses
      # {ObjectSchema#from_hash} under the hood.
      #
      # @param objects [Array<Hash>] The object array of hashes
      #
      # @return [Array<ObjectSchema>] A new array of ObjectSchema instances
      #
      def from_array(objects)
        Utils.normalize_array objects do |object|
          from_hash(object)
        end
      end
    end

    # The name of the object. It is referenced as a refined object type (`object.<name>`) and is unique within a
    # package.
    #
    # @return [String]
    #
    attr_reader :name

    # The object's properties when it is referenced in an argument context.
    #
    # @return [Array<Argument>]
    #
    def arguments
      @arguments.values
    end

    # Looks up a single argument member by name.
    #
    # @param name [String, Symbol] The name of the argument to look up.
    #
    # @return [Argument, nil] The matching argument, or `nil` if none is found.
    #
    def argument(name)
      @arguments[name.to_s]
    end

    # The object's properties when it is referenced in an attribute context.
    #
    # @return [Array<Attribute>]
    #
    def attributes
      @attributes.values
    end

    # Looks up a single attribute member by name.
    #
    # @param name [String, Symbol] The name of the attribute to look up.
    #
    # @return [Attribute, nil] The matching attribute, or `nil` if none is found.
    #
    def attribute(name)
      @attributes[name.to_s]
    end

    # The object's properties for the given context.
    #
    # @param context [Symbol] The context to resolve properties for. One of {CONTEXTS}.
    #
    # @raise [ArgumentError] If the context is not one of {CONTEXTS}.
    #
    # @return [Array<Argument>, Array<Attribute>] The properties that apply in the given context.
    #
    def properties(context)
      case context
      when :arguments
        arguments
      when :attributes
        attributes
      else
        raise ArgumentError, "context must be one of #{CONTEXTS.inspect}, got #{context.inspect}"
      end
    end
  end
end
