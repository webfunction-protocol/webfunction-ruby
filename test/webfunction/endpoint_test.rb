# frozen_string_literal: true

require "test_helper"

class WebFunctionEndpointTest < Minitest::Test
  def endpoint_hash
    {
      "name" => "do-thing",
      "returns" => %w[object null],
      "flags" => [:beta],
      "group" => "main",
      "docs" => "Does a thing",
      "arguments" => [
        { "name" => "id", "type" => "string", "choices" => [1, 2], "flags" => [:required],
          "docs" => "Arg docs", },
        "skip",
        { "name" => nil },
      ],
      "attributes" => [
        { "name" => "status", "type" => "string", "values" => [1], "flags" => [], "docs" => "" },
      ],
      "errors" => [
        { "code" => "X", "docs" => "e" },
      ],
    }
  end

  def test_instance_readers
    ep = WebFunction::Endpoint.from_hash(endpoint_hash)
    assert_equal "do-thing", ep.name
    assert_equal WebFunction::Type.union([WebFunction::Type.object, WebFunction::Type.null]), ep.returns
    assert_equal "object | null", ep.returns.to_s
    assert_equal %w[beta], ep.flags
    assert_equal "main", ep.group
    assert_equal "Does a thing", ep.docs
  end

  def test_from_hash_returns_nil_without_name_or_returns
    assert_nil WebFunction::Endpoint.from_hash("not a hash")
    assert_nil WebFunction::Endpoint.from_hash("returns" => "object")
    assert_nil WebFunction::Endpoint.from_hash("name" => "n")
  end

  def test_flags_empty_when_missing
    ep = WebFunction::Endpoint.from_hash("name" => "n", "returns" => "object")
    assert_equal [], ep.flags
  end

  def test_arguments_and_attributes_and_errors
    ep = WebFunction::Endpoint.from_hash(endpoint_hash)
    assert_equal ["id"], ep.arguments.compact.map(&:name)
    assert_equal ["status"], ep.attributes.compact.map(&:name)
    assert_equal ["X"], ep.errors.compact.map(&:code)
  end

  def test_arguments_empty_when_not_array
    ep = WebFunction::Endpoint.from_hash("name" => "n", "returns" => "object", "arguments" => {})
    assert_equal [], ep.arguments
  end

  def test_invoke_nil_args_becomes_empty_hash
    with_http_client_returning(status: 200, body: "{}") do
      WebFunction::Request.execute("https://x", args: nil)
    end
  end

  def test_invoke_success_parses_json
    with_http_client_returning(status: 200, body: '{"ok":true,"n":3}') do
      out = WebFunction::Request.execute("https://x", args: {})
      assert_equal true, out["ok"]
      assert_equal 3, out["n"]
    end
  end

  def test_invoke_bad_request_triple
    body = JSON.generate(["CODE_HERE", "human", { "x" => 1 }])
    with_http_client_returning(status: 400, body: body) do
      err = assert_raises(WebFunction::Error) do
        WebFunction::Request.execute("https://x")
      end
      assert_equal "CODE_HERE", err.code
      assert_equal "human", err.message
      assert_equal({ "x" => 1 }, err.details)
    end
  end

  def test_invoke_bad_request_string_body
    with_http_client_returning(status: 400, body: JSON.generate("plain")) do
      err = assert_raises(WebFunction::Error) do
        WebFunction::Request.execute("https://x")
      end
      assert_equal "WFN_BAD_REQUEST_ERROR", err.code
      assert_equal "Bad request", err.message
      assert_equal({ body: "plain" }, err.details)
    end
  end

  def test_invoke_bad_request_non_triple_array
    body = JSON.generate([1, 2])
    with_http_client_returning(status: 400, body: body) do
      err = assert_raises(WebFunction::Error) do
        WebFunction::Request.execute("https://x")
      end
      assert_equal "WFN_BAD_REQUEST_ERROR", err.code
      assert_equal "Bad request", err.message
      assert_equal [1, 2], err.details[:body]
    end
  end

  def test_invoke_unexpected_status
    with_http_client_returning(status: 500, body: "{}") do
      err = assert_raises(WebFunction::Error) do
        WebFunction::Request.execute("https://x")
      end
      assert_equal "WFN_UNEXPECTED_STATUS_CODE_ERROR", err.code
      assert_match(/500/, err.message)
    end
  end

  def test_invoke_json_parse_error
    with_http_client_returning(status: 200, body: "not json {") do
      err = assert_raises(WebFunction::Error) do
        WebFunction::Request.execute("https://x")
      end
      assert_equal "WFN_JSON_PARSE_ERROR", err.code
    end
  end

  def test_docs_coerces_nil
    ep = WebFunction::Endpoint.from_hash("name" => "n", "returns" => "object")
    assert_equal "", ep.docs
  end
end
