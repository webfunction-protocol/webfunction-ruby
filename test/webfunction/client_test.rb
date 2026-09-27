# frozen_string_literal: true

require "test_helper"

class WebFunctionClientTest < Minitest::Test
  def package_payload
    {
      "base_url" => "https://api.webfunction.com/",
      "pipeline_url" => "https://api.webfunction.com/run-pipeline",
      "name" => "Web Function",
      "endpoints" => [
        { "name" => "list-items", "returns" => "object" },
        { "name" => "other", "returns" => "object" },
      ],
    }
  end

  def test_from_package_endpoint_fetches_package_and_builds_client
    meta_url = "https://registry.test/package"
    with_http_client_returning(status: 200, body: JSON.generate(package_payload)) do
      client = WebFunction::Client.from_package_endpoint(meta_url)
      package = client.package
      assert_equal "https://api.webfunction.com/", package.base_url
      assert_equal "Web Function", package.name
      assert_equal 2, package.endpoints.count
    end
  end

  def test_from_package_endpoint_wraps_string_pipeline_so_calls_return_promises
    with_http_client_returning(status: 200, body: JSON.generate(package_payload)) do
      client = WebFunction::Client.from_package_endpoint("https://api.webfunction.com/", pipelined: true)
      promise = client.list_items
      assert_instance_of WebFunction::Promise, promise
    end
  end

  def test_dynamic_endpoint_invokes_joined_url_without_pipeline
    package = WebFunction::Package.from_hash(package_payload)
    client = WebFunction::Client.from_package(package)

    request = with_http_client_returning(status: 200, body: JSON.generate({ "done" => true })) do
      out = client.list_items(q: "a")
      assert_equal({ "done" => true }, out)
    end

    assert request
    assert_equal "https://api.webfunction.com/list-items", request[:url]
    assert_equal({ q: "a" }.to_json, request[:body])
  end

  def test_hyphenated_endpoint_name_maps_to_underscore_method
    package = WebFunction::Package.from_hash(package_payload)
    client = WebFunction::Client.from_package(package)

    with_http_client_returning(status: 200, body: JSON.generate({ "n" => "list-items" })) do
      out = client.list_items
      assert_equal "list-items", out["n"]
    end
  end

  def test_with_pipeline_returns_promise_from_endpoint_call
    package = WebFunction::Package.from_hash(package_payload)
    client = WebFunction::Client.from_package(package, pipelined: true)

    with_http_client_returning(status: 200, body: JSON.generate([{ "merged" => 1 }])) do
      promise = client.list_items(x: 2)
      assert_instance_of WebFunction::Promise, promise
      assert_equal({ "merged" => 1 }, promise.resolve)
    end
  end

  def test_unknown_endpoint_raises_no_method_error
    package = WebFunction::Package.from_hash("base_url" => "https://api.webfunction.com/", "endpoints" => [])
    client = WebFunction::Client.from_package(package)

    assert_raises(NoMethodError) { client.missing }
  end
end
