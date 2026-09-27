# frozen_string_literal: true

module WebFunction
  # A module that provides a flaggable interface. Flags are used to define the behavior of an object.
  #
  # @example
  #   class Endpoint
  #     include Flaggable
  #
  #     def initialize(name:, flags: [])
  #       @name = name
  #       @flags = flags
  #     end
  #   end
  #
  #   endpoint = Endpoint.new(name: "get_user", flags: ["private"])
  #   endpoint.flag?("private") # => true
  #   endpoint.flag?("public") # => false
  #
  module Flaggable
    # List of flags. See the [available flags section][2] on the Web Function
    # website for a complete list of flags available.
    #
    # @return [Array<String>]
    #
    # [2]: https://webfunction.org/package#available-flags
    #
    attr_reader :flags

    # Whether the endpoint declares the given flag.
    #
    # @param flag [String] The flag to check for.
    #
    # @return [Boolean]
    #
    def flag?(flag)
      @flags.include?(flag)
    end
  end
end
