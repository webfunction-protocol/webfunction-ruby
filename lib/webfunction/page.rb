# frozen_string_literal: true

module WebFunction
  # A page of results from a paginated endpoint.
  #
  # Paginated responses follow the Web Function pagination contract: a JSON object with
  # `page`, `next`, and `previous` keys. {Request} detects this shape and returns a {Page}
  # instead of a bare Hash. The `next` and `previous` values are opaque request bodies —
  # call {#next_page} or {#previous_page} to fetch the adjacent page; do not construct or modify them.
  #
  # @example
  #   page = WebFunction::Request.execute(
  #     "https://api.example.com/list-people",
  #     args: { filters: { first_name: "Joe" } },
  #   )
  #   page.page        # => [{ "person_id" => "...", ... }, ...]
  #   page.next?       # => true
  #   next_page = page.next_page
  #   next_page.previous? # => true
  #
  # See the [pagination specification][0] for the full contract.
  #
  # [0]: https://webfunction.org/pagination
  #
  class Page
    include Enumerable

    def initialize(page:, next_body:, previous_body:, url:, bearer_auth: nil, version: nil)
      @page = page
      @next_body = next_body
      @previous_body = previous_body
      @url = url
      @bearer_auth = bearer_auth
      @version = version
    end

    class << self
      # Whether +response+ matches the paginated response shape.
      #
      # @param response [Object] A parsed JSON response
      #
      # @return [Boolean]
      #
      def paginated?(response)
        response.is_a?(Hash) &&
          response.key?("page") &&
          response.key?("next") &&
          response.key?("previous") &&
          response["page"].is_a?(Array) &&
          (response["next"].nil? || response["next"].is_a?(Hash)) &&
          (response["previous"].nil? || response["previous"].is_a?(Hash))
      end

      # Wraps a paginated response in a {Page}, or returns +response+ unchanged.
      #
      # @param response [Object] A parsed JSON response
      # @param request [Request] The request that produced the response
      #
      # @return [Page, Object]
      #
      def wrap(response, request:)
        return response unless paginated?(response)

        new(
          page: response["page"],
          next_body: response["next"],
          previous_body: response["previous"],
          url: request.url,
          bearer_auth: request.bearer_auth,
          version: request.version,
        )
      end
    end

    # The items on the current page.
    #
    # @return [Array]
    #
    attr_reader :page

    # Whether a next page is available.
    #
    # @return [Boolean]
    #
    def next?
      !@next_body.nil?
    end

    # Whether a previous page is available.
    #
    # @return [Boolean]
    #
    def previous?
      !@previous_body.nil?
    end

    # Fetches the next page by posting the opaque `next` body to the same endpoint.
    #
    # @return [Page, nil] The next page, or `nil` if there is none
    #
    def next_page
      fetch(@next_body)
    end

    # Fetches the previous page by posting the opaque `previous` body to the same endpoint.
    #
    # @return [Page, nil] The previous page, or `nil` if there is none
    #
    def previous_page
      fetch(@previous_body)
    end

    # Iterates over the items on the current page.
    #
    # @yield [Object] Each item in {#page}
    #
    # @return [Enumerator, Page]
    #
    def each(&block)
      return enum_for(:each) unless block

      @page.each(&block)
      self
    end

    private

    def fetch(body)
      return nil if body.nil?

      Request.execute(@url, bearer_auth: @bearer_auth, version: @version, args: body)
    end
  end
end
