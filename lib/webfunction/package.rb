# frozen_string_literal: true

module WebFunction
  # Organize, document, and validate endpoints. A package facilitates {Endpoint} discovery and integration by providing
  # standardized metadata about them.
  #
  # A package bundles a base URL together with the endpoints it exposes, as well as optional metadata such as a name,
  # version information, top-level documentation, and a list of common errors.
  #
  # See the [package specification][0] on the Web Function website for the full description of every recognized key and
  # its constraints.
  #
  # [0]: https://webfunction.org/package
  #
  class Package
    include Flaggable

    def initialize(base_url:, pipeline_url: nil, name: nil, version: nil, docs: nil, flags: [], versions: [],
                   endpoints: [], errors: [], objects: [])
      @base_url = base_url
      @pipeline_url = pipeline_url
      @name = name
      @version = version
      @docs = docs.to_s
      @flags = flags
      @versions = versions
      @endpoints = endpoints.to_h { |e| [e.name, e] }
      @errors = errors.to_h { |e| [e.code, e] }
      @objects = objects.to_h { |o| [o.name, o] }
    end

    class << self
      # Instantiate a new Package from a hash.
      #
      # @param package [Hash] The package hash
      #
      # @return [Package] A new Package instance
      #
      def from_hash(package)
        new(
          base_url: package["base_url"],
          pipeline_url: package["pipeline_url"],
          name: package["name"],
          version: package["version"],
          docs: package["docs"],
          flags: Utils.normalize_array_of_strings(package["flags"]),
          versions: Utils.normalize_array_of_strings(package["versions"]),
          endpoints: Endpoint.from_array(package["endpoints"]),
          errors: DocumentedError.from_array(package["errors"]),
          objects: ObjectSchema.from_array(package["objects"]),
        )
      end
    end

    # The base URL for the package. Endpoint URLs are formed by joining this base URL with each endpoint's name.
    #
    # This is required for the package to be valid and MUST use the HTTP or HTTPS scheme.
    #
    # @return [String]
    #
    attr_reader :base_url

    # A function pipelining URL used to batch several endpoint invocations into a single request. See the pipelining
    # specification for more information.
    #
    # @return [String, nil]
    #
    attr_reader :pipeline_url

    # The name of the package.
    #
    # @return [String, nil]
    #
    attr_reader :name

    # The version that this package describes. An opaque string.
    #
    # This MUST be present when the `versioned` flag is set. See the versioning specification for more information.
    #
    # @return [String, nil]
    #
    attr_reader :version

    # Top-level documentation for the package. It must be formatted as markdown.
    #
    # @return [String]
    #
    attr_reader :docs

    # The versions that are available. Each entry is an opaque string.
    #
    # This MUST be present when the `versioned` flag is set. See the versioning specification for more information.
    #
    # @return [Array<String>]
    #
    attr_reader :versions

    # The {Pipeline} for this package, built from {#pipeline_url}, or `nil` when the package does not declare a
    # pipeline URL.
    #
    # @return [Pipeline, nil]
    #
    def pipeline
      unless pipeline_url
        return
      end

      Pipeline.new(pipeline_url)
    end

    # The endpoints declared by this package.
    #
    # @return [Array<Endpoint>]
    #
    def endpoints
      @endpoints.values
    end

    # Looks up a single endpoint by name. Underscores in the given name are converted to hyphens so that Ruby-style
    # names (e.g. `:find_user_by`) match the hyphenated endpoint names used in packages (e.g. `find-user-by`).
    #
    # @param name [String, Symbol] The name of the endpoint to look up.
    #
    # @return [Endpoint, nil] The matching endpoint, or `nil` if none is found.
    #
    def endpoint(name)
      @endpoints[name.to_s.gsub("_", "-")]
    end

    # The list of common errors that can be returned by any endpoint in this package. Only refer to this list if an
    # endpoint uses the `error_triple` flag. See the error specification for more information.
    #
    # @return [Array<DocumentedError>]
    #
    def errors
      @errors.values
    end

    # Looks up a single common error by its machine-readable code.
    #
    # @param code [String, Symbol] The error code to look up.
    #
    # @return [DocumentedError, nil] The matching error, or `nil` if none is found.
    #
    def error(code)
      @errors[code.to_s]
    end

    # The named object definitions declared by this package. Each can be referenced as a refined object type
    # (`object.<name>`) anywhere a type is expected.
    #
    # @return [Array<ObjectSchema>]
    #
    def objects
      @objects.values
    end

    # Looks up a single object definition by name, resolved for the given context.
    #
    # An `object.` reference appears in either an argument or attribute context, which determines which set of members
    # applies. The `context` selects the member set that is relevant; an object that does not define members for the
    # requested context is treated as absent and `nil` is returned.
    #
    # @param name [String, Symbol] The name of the object to look up.
    # @param context [Symbol] The context the object is referenced in. One of {ObjectSchema::CONTEXTS}
    #   (`:arguments` or `:attributes`).
    #
    # @raise [ArgumentError] If the context is not one of {ObjectSchema::CONTEXTS}.
    #
    # @return [ObjectSchema, nil] The matching object, or `nil` if none is found or it defines no members for the
    #   given context.
    #
    def object(name, context:)
      object = @objects[name.to_s]

      unless object
        return
      end

      if object.properties(context).empty?
        return
      end

      object
    end

    # Whether the package is versioned, i.e. whether it declares the `versioned` flag. A versioned package is selected
    # using the `Api-Version` header.
    #
    # @return [Boolean]
    #
    def versioned?
      flag?("versioned")
    end
  end
end
