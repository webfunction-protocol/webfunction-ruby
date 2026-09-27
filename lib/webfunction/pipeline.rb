# frozen_string_literal: true

module WebFunction
  # A pipeline is a sequence of steps that are executed in order.
  #
  # @example
  #   pipeline = WebFunction::Pipeline.new("https://pipe.example/exec")
  #   pipeline.add_step({ url: "https://a", headers: {}, body: {} })
  #   pipeline.add_step({ url: "https://b", headers: {}, body: {} })
  #   pipeline.execute(returns: :all) # => [{ "a" => 1 }, { "b" => 2 }]
  #
  class Pipeline
    def initialize(url)
      @url = url
      @steps = []
      @promises = []
    end

    # Adds a step to the pipeline.
    #
    # @param step [Hash] The step to add
    #
    # @return [Promise] A new Promise instance
    #
    def add_step(step)
      n = @promises.count
      promise = Promise.new(self, "$[#{n}]")

      @steps << step
      @promises << promise

      promise
    end

    # Executes the pipeline.
    #
    # @param returns [String, Symbol] The return type or a JSONPath expression to return a specific value.
    #
    # @return [Object] The response returned by the pipeline.
    #
    def execute(returns: :all)
      case returns
      when :all
        responses = Request.execute(@url, args: {
          steps: @steps,
          returns: "$",
        },
        )

        responses.each_with_index do |response, index|
          @promises[index].value = response
        end

        reset!

        responses
      when :last
        response = Request.execute(@url, args: {
          steps: @steps,
          returns: "$[-1:]",
        },
        )

        @promises.last.value = response

        reset!

        response
      else
        response = Request.execute(@url, args: {
          steps: @steps,
          returns: returns,
        },
        )

        reset!

        response
      end
    end

    # Resets the pipeline.
    #
    # @return [void]
    #
    def reset!
      @steps = []
      @promises = []
    end
  end
end
