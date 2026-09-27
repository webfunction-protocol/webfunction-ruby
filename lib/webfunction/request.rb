# frozen_string_literal: true

module WebFunction
  # A request allows you to invoke a Web Function endpoint via an HTTP client.
  #
  # @example
  #   request = WebFunction::Request.new("https://api.example.com/endpoint")
  #   request.execute # => { "a" => 1 }
  #
  class Request
    def initialize(url, bearer_auth: nil, version: nil, args: {})
      @url = url
      @bearer_auth = bearer_auth
      @version = version
      @args = args || {}
    end

    class << self
      # The HTTP client used to execute the request.
      #
      # To provide a custom HTTP client instead of the default (which uses Excon),
      # set this to any object responding to #call. For example, a Proc or a lambda.
      #
      # The contract is:
      #
      #     client.call(url, headers, body)
      #
      # - url:    [String] The full URL to post to (not just the hostname or path).
      # - headers:[Hash<String,String>] HTTP headers, e.g. { "Content-Type" => "application/json" }
      # - body:   [String] The JSON body to post.
      #
      # The client must return a two-element Array: [status, body]:
      #
      # - status: [Integer] HTTP status code (e.g. 200, 400, 500)
      # - body:   [String] Raw response body as a string
      #
      # @example
      #   WebFunction::Endpoint.http_client = ->(url, headers, args) {
      #     http_response = MyHTTP.post(url, headers: headers, body: JSON.generate(args))
      #     [http_response.status, http_response.body]
      #   }
      #
      attr_accessor :http_client

      # Executes a request.
      #
      # @param url [String] The URL of the request
      # @param bearer_auth [String] The bearer authentication token
      # @param version [String] The API version to use
      # @param args [Hash] The arguments to send to the request
      #
      # @return [Object, Page] The response returned by the request. Paginated
      #   responses are wrapped in a {Page}.
      def execute(url, bearer_auth: nil, version: nil, args: {})
        request = new(url, bearer_auth: bearer_auth, version: version, args: args)
        request.execute
      end
    end

    self.http_client = proc do |url, headers, body|
      response = Excon.post(url, headers: headers, body: body)
      [response.status, response.body]
    end

    # The URL of the request.
    #
    # @return [String] The URL of the request
    #
    attr_reader :url

    # The bearer authentication token.
    #
    # @return [String] The bearer authentication token
    #
    attr_reader :bearer_auth

    # The API version to use.
    #
    # @return [String] The API version to use
    #
    attr_reader :version

    # The arguments to send to the request.
    #
    # @return [Hash] The arguments to send to the request
    #
    attr_reader :args

    # The headers to send to the request.
    #
    # @return [Hash] The headers to send to the request
    #
    def headers
      headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "webfunction/#{WebFunction::VERSION}",
        "Accept-Encoding": "gzip",
      }

      if @bearer_auth
        headers["Authorization"] = "Bearer #{@bearer_auth}"
      end

      if @version
        headers["Api-Version"] = @version
      end

      headers
    end

    # Returns the request as a pipeline step.
    #
    # @return [Hash] The request as a pipeline step
    #
    def as_pipeline_step
      {
        url: @url,
        headers: headers,
        body: @args,
      }
    end

    # Executes the request.
    #
    # When the response matches the pagination contract (`page`, `next`, and
    # `previous` keys), it is wrapped in a {Page} so callers can navigate with
    # {Page#next_page} and {Page#previous_page}.
    #
    # @raise [WebFunction::UnexpectedStatusCodeError] If the status code is not 200 or 400
    # @raise [WebFunction::JsonParseError] If the response is not valid JSON
    # @raise [WebFunction::BadRequestError] If the response is a bad request
    #
    # @return [Object, Page] The response returned by the request
    #
    def execute
      status, body = self.class.http_client.call(@url, headers, JSON.generate(@args))

      unless [200, 400].include?(status)
        raise WebFunction::UnexpectedStatusCodeError.new("Unexpected status code (#{status})",
          details: {
            status_code: status,
            raw_body: body,
          },
        )
      end

      begin
        result = JSON.parse(body)
      rescue JSON::ParserError => e
        raise WebFunction::JsonParseError.new(e.message,
          details: {
            status_code: status,
            raw_body: body,
            original_exception: e,
          },
        )
      end

      if status == 400
        code = "WFN_BAD_REQUEST_ERROR"
        message = "Bad request"
        details = { body: result }

        if result.is_a?(Array) && result.length == 3 && result[0].is_a?(String) && result[1].is_a?(String)
          code = result[0]
          message = result[1]
          details = result[2]
        end

        raise WebFunction::BadRequestError.new(message, code: code, details: details)
      end

      Page.wrap(result, request: self)
    end
  end
end
