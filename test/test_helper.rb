# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "webfunction"

require "minitest/autorun"

module WebFunctionTestHelpers
  def with_http_client_returning(status:, body:)
    request = nil
    original_http_client = WebFunction::Request.http_client

    WebFunction::Request.http_client = proc do |request_url, request_headers, request_body|
      request = {
        url: request_url,
        headers: request_headers,
        body: request_body,
      }

      [status, body]
    end

    yield

    request
  ensure
    WebFunction::Request.http_client = original_http_client
  end
end

module Minitest
  class Test
    include WebFunctionTestHelpers
  end
end
