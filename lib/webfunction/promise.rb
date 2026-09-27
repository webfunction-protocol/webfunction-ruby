# frozen_string_literal: true

module WebFunction
  # A promise is a placeholder for a value that will be resolved later.
  #
  # @example
  #   pipeline = WebFunction::Pipeline.new("https://pipe.example/exec")
  #   promise = pipeline.add_step({})
  #   promise.resolve # => { "a" => 1 }
  #
  class Promise
    def initialize(pipeline, path)
      @pipeline = pipeline
      @path = Path.new(path)
      @value = nil
    end

    # A path is a JSONPath expression that can be used to resolve a value from a response.
    #
    # @example
    #   path = WebFunction::Promise::Path.new("$[0]")
    #   path.to_s # => "$[0]"
    #   path[0] # => { "a" => 1 }
    #
    class Path
      def initialize(path)
        @path = path
      end

      # Returns the string representation of the path.
      #
      # @return [String] The string representation of the path
      #
      def to_s
        @path
      end

      # Returns the JSON representation of the path.
      #
      # @param args [Array] The arguments to pass to the JSON.generate method
      #
      # @return [String] The JSON representation of the path
      #
      def to_json(*args)
        @path.to_json(*args)
      end

      # Returns a new path with the given key.
      #
      # @param key [String, Symbol, Integer] The key to add to the path
      #
      # @return [Path] A new Path instance
      #
      def [](key)
        case key
        when String, Symbol
          mutate("#{@path}.#{key}")
        when Integer
          mutate("#{@path}[#{key}]")
        else
          raise ArgumentError
        end
      end

      # Mutates the path with the given path.
      #
      # @param path [String] The path to mutate
      #
      # @return [Path] A new Path instance
      #
      def mutate(path)
        Path.new(path)
      end
    end

    # The value of the promise.
    #
    # @return [Object] The value of the promise
    #
    attr_writer :value

    # Returns the string representation of the promise.
    #
    # @return [String] The string representation of the promise
    #
    def to_s
      if @value
        @value.to_s
      else
        @path.to_s
      end
    end

    # Returns the JSON representation of the promise.
    #
    # @param args [Array] The arguments to pass to the JSON.generate method
    #
    # @return [String] The JSON representation of the promise
    #
    def to_json(*args)
      if @value
        @value.to_json(*args)
      else
        @path.to_json(*args)
      end
    end

    # Returns the value of the promise at the given key.
    #
    # @param key [String, Symbol, Integer] The key to resolve
    #
    # @return [Object] The value of the promise at the given key
    #
    def [](key)
      if @value
        @value[key]
      else
        @path[key]
      end
    end

    # Returns the value of the promise.
    #
    # @raise [WebFunction::UnresolvedPromiseError] If the promise is not resolved
    #
    # @return [Object] The value of the promise
    #
    def value
      unless @value
        raise WebFunction::UnresolvedPromiseError
      end

      @value
    end

    # Resolves the promise.
    #
    # @return [Object] The value of the promise
    #
    def resolve
      if @value
        return @value
      end

      @pipeline.execute

      value
    end
  end
end
