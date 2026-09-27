# frozen_string_literal: true

module WebFunction
  # Arguments are used to define Web Function {Endpoint} request parameters.
  #
  # See the [arguments section][0] on the Web Function website for more details.
  #
  # [0]: https://webfunction.org/package#arguments
  #
  class Argument
    include Flaggable

    def initialize(name:, type:, group: nil, choices: [], flags: [], docs: nil)
      @name = name
      @type = Type.parse(type)
      @group = group
      @choices = choices
      @flags = flags
      @docs = docs.to_s
    end

    class << self
      # Instantiate a new Argument from a hash, typically coming from a {Package}.
      #
      # @param argument [Hash]
      #
      # @return [Argument, nil]
      #
      def from_hash(argument)
        unless argument.is_a?(Hash)
          return
        end

        unless argument["name"]
          return
        end

        unless argument["type"]
          return
        end

        new(
          name: argument["name"],
          type: argument["type"],
          group: argument["group"],
          choices: [*argument["choices"]],
          flags: Utils.normalize_array_of_strings(argument["flags"]),
          docs: argument["docs"],
        )
      end

      # Instantiate a collection of Argument from an array of hash, typically coming from a {Package}. Uses
      # {Argument#from_hash} under the hood.
      #
      # @param arguments [Array<Hash>]
      #
      # @return [Array<Argument>]
      #
      def from_array(arguments)
        Utils.normalize_array arguments do |argument|
          from_hash(argument)
        end
      end
    end

    # The name of the argument.
    #
    # @return [String]
    #
    attr_reader :name

    # The type of the argument. It must be one of:
    #
    # - object
    # - array
    # - string
    # - number
    # - boolean
    #
    # @return [String]
    #
    attr_reader :type

    # A name used to categorize or group similar arguments together. This should be used by documentation tools to
    # organize related arguments.
    #
    # @return [String]
    #
    attr_reader :group

    # An array specifying the exact, case-sensitive values that are permitted for this argument. Each value in the 
    # choices array must conform to the data type specified in the argument's type key.
    #
    # Note that if the argument type is array, choices may contain strings or numbers representing the allowed values
    # that can be included in the array.
    #
    # @return [Array]
    #
    attr_reader :choices

    # Description of the argument. It must be formatted as markdown.
    #
    # @return [String]
    #
    attr_reader :docs

    # Whether the argument is required.
    #
    # @return [Boolean]
    #
    def required?
      flag?("required")
    end

    # Whether the argument is optional.
    #
    # @return [Boolean]
    #
    def optional?
      !required?
    end
  end
end
