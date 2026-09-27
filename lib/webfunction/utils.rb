# frozen_string_literal: true

module WebFunction
  # Internal utility methods.
  #
  # @api private
  #
  module Utils
    module_function

    # Normalizes a collection. Yields each item to the block if a block is given, otherwise returns the item.
    # Any `nil` items are removed.
    #
    # @param collection [Array] The collection to normalize
    #
    # @return [Array] The normalized array
    #
    def normalize_array(collection)
      unless collection.is_a?(Array)
        return []
      end

      items = collection.map do |item|
        if block_given?
          yield item
        else
          item
        end
      end

      items.compact
    end

    # Normalizes an array of strings. Uses #normalize_array under the hood.
    #
    # @param collection [Array] The collection to normalize
    #
    # @return [Array] The normalized array
    #
    def normalize_array_of_strings(collection)
      normalize_array(collection) { |item| item.to_s }
    end

    def get_body_from_url(url, extra_query_params: {})
      url = add_query_params(url, extra_query_params)
      response = ::Excon.get(url, headers: {
        "User-Agent": "webfunction/#{::WebFunction::VERSION}",
        "Accept-Encoding": "gzip",
      })

      response.body
    end

    def add_query_params(url, params = {})
      uri = ::URI.parse(url)
      existing_params = ::URI.decode_www_form(uri.query || "").to_h
      new_params = params.reject { |_, value| value.nil? }.transform_keys(&:to_s)
      merged_params = existing_params.merge(new_params)

      unless merged_params.empty?
        uri.query = ::URI.encode_www_form(merged_params)
      end

      uri.to_s
    end
  end
end
