# frozen_string_literal: true

module WebFunction
  # Represents an error definition as described in a Web Function package.
  #
  # An error definition documents the possible errors that an endpoint might return, including a machine-readable error
  # code and a human-readable description.
  #
  # See the [error definition documentation][0] on the Web Function website for more details, including recognized keys
  # and usage recommendations.
  #
  # [0]: https://webfunction.org/package#error-definition
  #
  class DocumentedError
    def initialize(code:, docs: nil)
      @code = code
      @docs = docs.to_s
    end

    class << self
      # Creates a new DocumentedError from a hash.
      #
      # @param error [Hash] The error hash
      #
      # @return [DocumentedError] A new DocumentedError instance
      #
      def from_hash(error)
        unless error.is_a?(Hash)
          return
        end

        unless error["code"]
          return
        end

        new(
          code: error["code"],
          docs: error["docs"],
        )
      end

      # Creates a new DocumentedError from an array of hashes. Uses {DocumentedError#from_hash} under the hood.
      #
      # @param errors [Array<Hash>] The error array of hashes
      #
      # @return [Array<DocumentedError>] A new array of DocumentedError instances
      #
      def from_array(errors)
        Utils.normalize_array errors do |error|
          from_hash(error)
        end
      end
    end

    # The machine-readable code of the error.
    #
    # @return [String]
    #
    attr_reader :code

    # The documentation of the error.
    #
    # @return [String]
    #
    attr_reader :docs
  end
end
