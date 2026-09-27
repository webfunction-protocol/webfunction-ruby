# frozen_string_literal: true

module WebFunction
  # Represents an endpoint as described in a Web Function package.
  #
  # An endpoint defines an operation that can be performed via a Web Function API. Endpoints declare their name,
  # documentation, arguments (inputs), attributes (outputs), and the possible errors that may occur when invoking them.
  #
  # Endpoints are described as objects in each package under the `"endpoints"` key. For more information, see:
  #
  # - [Web Function package docs](https://webfunction.org/package)
  # - [Web Function endpoint docs](https://webfunction.org/endpoint)
  #
  # This class provides methods for accessing endpoint metadata (name, docs, arguments, attributes, errors) and
  # supports invocation via HTTP.
  #
  # Typical tasks include:
  #
  # - Querying endpoint name or documentation
  # - Enumerating the arguments or attributes definitions
  # - Invoking the endpoint through HTTP using required inputs
  #
  # See: https://webfunction.org/endpoint for more details on endpoint structure and contract.
  #
  class Endpoint
    include Flaggable

    def initialize(name:, returns:, flags: [], group: nil, docs: nil, arguments: [], attributes: [], errors: [])
      @name = name
      @returns = Type.parse(returns)
      @flags = flags
      @group = group
      @docs = docs
      @arguments = arguments.to_h { |a| [a.name, a] }
      @attributes = attributes.to_h { |a| [a.name, a] }
      @errors = errors.to_h { |e| [e.code, e] }
    end

    class << self
      # Invokes an endpoint through HTTP using the given URL, bearer authentication, version, and arguments.
      #
      # @param url [String] The URL of the endpoint to invoke
      # @param bearer_auth [String] The bearer authentication token
      # @param version [String] The API version to use
      # @param args [Hash] The arguments to send to the endpoint
      #
      # @return [Object] The response returned by the endpoint
      #
      def invoke(url, bearer_auth: nil, version: nil, args: {})
        Request.execute(url, bearer_auth: bearer_auth, version: version, args: args)
      end

      # Creates a new Endpoint from a hash.
      #
      # @param endpoint [Hash] The endpoint hash
      #
      # @return [Endpoint] A new Endpoint instance
      #
      def from_hash(endpoint)
        unless endpoint.is_a?(Hash)
          return
        end

        unless endpoint["name"]
          return
        end

        unless endpoint["returns"]
          return
        end

        new(
          name: endpoint["name"],
          returns: endpoint["returns"],
          flags: Utils.normalize_array_of_strings(endpoint["flags"]),
          group: endpoint["group"],
          docs: endpoint["docs"].to_s,
          arguments: Argument.from_array(endpoint["arguments"]),
          attributes: Attribute.from_array(endpoint["attributes"]),
          errors: DocumentedError.from_array(endpoint["errors"]),
        )
      end

      # Creates a new Endpoint from an array of hashes. Uses {Endpoint#from_hash} under the hood.
      #
      # @param endpoints [Array<Hash>] The endpoint array of hashes
      #
      # @return [Array<Endpoint>] A new array of Endpoint instances
      #
      def from_array(endpoints)
        Utils.normalize_array endpoints do |endpoint|
          from_hash(endpoint)
        end
      end
    end

    # The {Client} used to invoke this endpoint. It is assigned when the endpoint is loaded from a package and is
    # required by {#call}.
    #
    # @return [Client, nil]
    #
    attr_accessor :client

    # The suffix for the endpoint URL, appended to the package's base URL to form the full endpoint URL. Endpoint names
    # are unique within a package; overloading (two endpoints sharing the same name) is not permitted.
    #
    # @return [String]
    #
    attr_reader :name

    # The JSON type(s) returned by the endpoint. A non-empty array whose entries are each one of:
    #
    # - object
    # - array
    # - string
    # - number
    # - boolean
    # - null
    #
    # @return [Array<String>]
    #
    attr_reader :returns

    # A name used to categorize or group similar endpoints together. This should be used by documentation tools to
    # organize related endpoints.
    #
    # @return [String, nil]
    #
    attr_reader :group

    # Documentation for the endpoint. It must be formatted as markdown.
    #
    # @return [String]
    #
    attr_reader :docs

    # Invokes the endpoint through its assigned {#client}, passing the given arguments.
    #
    # @param args [Hash] The arguments to send to the endpoint.
    #
    # @raise [RuntimeError] If no client has been assigned to the endpoint.
    #
    # @return [Object] The decoded response returned by the endpoint.
    #
    def call(args = {})
      unless client
        raise "Client must be set to invoke an endpoint"
      end

      client.call(name, args)
    end

    # The list of errors specific to this endpoint. Clients SHOULD only refer to this list if the endpoint uses the
    # `error_triple` flag. See the error specification for more information.
    #
    # @return [Array<DocumentedError>]
    #
    def errors
      @errors.values
    end

    # Looks up a single endpoint error by its machine-readable code.
    #
    # @param code [String, Symbol] The error code to look up.
    #
    # @return [DocumentedError, nil] The matching error, or `nil` if none is found.
    #
    def error(code)
      @errors[code.to_s]
    end

    # The attributes of the object returned by the endpoint. Relevant when the endpoint returns an `object`.
    #
    # @return [Array<Attribute>]
    #
    def attributes
      @attributes.values
    end

    # Looks up a single returned attribute by name.
    #
    # @param name [String, Symbol] The name of the attribute to look up.
    #
    # @return [Attribute, nil] The matching attribute, or `nil` if none is found.
    #
    def attribute(name)
      @attributes[name.to_s]
    end

    # The arguments required by the endpoint. The array is empty when the endpoint requires no arguments.
    #
    # @return [Array<Argument>]
    #
    def arguments
      @arguments.values
    end

    # Looks up a single argument by name.
    #
    # @param name [String, Symbol] The name of the argument to look up.
    #
    # @return [Argument, nil] The matching argument, or `nil` if none is found.
    #
    def argument(name)
      @arguments[name.to_s]
    end

    # Whether the endpoint requires authentication via a bearer token, i.e. whether it declares the `bearer_auth` flag.
    #
    # @return [Boolean]
    #
    def bearer_auth?
      flag?("bearer_auth")
    end

    # Whether the endpoint returns a bearer token in its response, i.e. whether it declares the `capture_bearer` flag.
    # See the authentication specification for more information.
    #
    # @return [Boolean]
    #
    def capture_bearer?
      flag?("capture_bearer")
    end

    # Whether the endpoint supports pagination, i.e. whether it declares the `paginated` flag.
    #
    # @return [Boolean]
    #
    def paginated?
      flag?("paginated")
    end

    # Whether the endpoint is intended for internal use and is not part of the public API, i.e. whether it declares the
    # `private` flag. Documentation tooling SHOULD omit endpoints with this flag from generated or
    # published documentation.
    #
    # @return [Boolean]
    #
    def private?
      flag?("private")
    end
  end
end
