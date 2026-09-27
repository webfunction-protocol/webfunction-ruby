# frozen_string_literal: true

require "test_helper"

class WebFunctionPageTest < Minitest::Test
  def page_payload(page:, next_body: nil, previous_body: nil)
    {
      "previous" => previous_body,
      "page" => page,
      "next" => next_body,
    }
  end

  def with_http_client_sequence(*responses)
    requests = []
    original_http_client = WebFunction::Request.http_client
    queue = responses.dup

    WebFunction::Request.http_client = proc do |request_url, request_headers, request_body|
      requests << {
        url: request_url,
        headers: request_headers,
        body: request_body,
      }

      status, body = queue.shift
      [status, body]
    end

    yield

    requests
  ensure
    WebFunction::Request.http_client = original_http_client
  end

  def test_paginated_predicate_accepts_valid_shape
    assert WebFunction::Page.paginated?(page_payload(page: [{ "id" => 1 }]))
    assert WebFunction::Page.paginated?(page_payload(page: [], next_body: { "after" => "1" }))
  end

  def test_paginated_predicate_rejects_invalid_shapes
    refute WebFunction::Page.paginated?([{ "id" => 1 }])
    refute WebFunction::Page.paginated?({ "page" => [{ "id" => 1 }] })
    refute WebFunction::Page.paginated?(page_payload(page: "not-an-array"))
    refute WebFunction::Page.paginated?(page_payload(page: [], next_body: "token"))
    refute WebFunction::Page.paginated?({ "items" => [], "next" => nil, "previous" => nil })
  end

  def test_request_execute_wraps_paginated_response
    payload = page_payload(
      page: [{ "person_id" => "person_1" }],
      next_body: { "after" => "person_1", "per_page" => 10 },
    )

    with_http_client_returning(status: 200, body: JSON.generate(payload)) do
      result = WebFunction::Request.execute(
        "https://api.example.com/list-people",
        args: { filters: { first_name: "Joe" } },
      )

      assert_instance_of WebFunction::Page, result
      assert_equal [{ "person_id" => "person_1" }], result.page
      assert result.next?
      refute result.previous?
      assert_nil result.previous_page
    end
  end

  def test_request_execute_leaves_non_paginated_response_unchanged
    with_http_client_returning(status: 200, body: JSON.generate({ "id" => "123", "name" => "Ada" })) do
      result = WebFunction::Request.execute("https://api.example.com/find-user", args: { id: "123" })

      assert_equal({ "id" => "123", "name" => "Ada" }, result)
    end
  end

  def test_next_posts_opaque_body_and_returns_page
    first = page_payload(
      page: [{ "person_id" => "person_1" }],
      next_body: { "after" => "person_1", "per_page" => 10, "filters" => { "first_name" => "Joe" } },
    )
    second = page_payload(
      page: [{ "person_id" => "person_2" }],
      previous_body: { "before" => "person_2", "per_page" => 10, "filters" => { "first_name" => "Joe" } },
    )

    requests = with_http_client_sequence(
      [200, JSON.generate(first)],
      [200, JSON.generate(second)],
    ) do
      page = WebFunction::Request.execute(
        "https://api.example.com/list-people",
        bearer_auth: "token",
        version: "2024-01-01",
        args: { filters: { first_name: "Joe" } },
      )

      next_page = page.next_page

      assert_instance_of WebFunction::Page, next_page
      assert_equal [{ "person_id" => "person_2" }], next_page.page
      refute next_page.next?
      assert next_page.previous?
    end

    assert_equal 2, requests.length
    assert_equal "https://api.example.com/list-people", requests[1][:url]
    assert_equal(
      { "after" => "person_1", "per_page" => 10, "filters" => { "first_name" => "Joe" } }.to_json,
      requests[1][:body],
    )
    assert_equal "Bearer token", requests[1][:headers]["Authorization"]
    assert_equal "2024-01-01", requests[1][:headers]["Api-Version"]
  end

  def test_previous_posts_opaque_body_and_returns_page
    current = page_payload(
      page: [{ "person_id" => "person_2" }],
      previous_body: { "before" => "person_2" },
    )
    prior = page_payload(
      page: [{ "person_id" => "person_1" }],
      next_body: { "after" => "person_1" },
    )

    requests = with_http_client_sequence(
      [200, JSON.generate(current)],
      [200, JSON.generate(prior)],
    ) do
      page = WebFunction::Request.execute("https://api.example.com/list-people")
      previous_page = page.previous_page

      assert_equal [{ "person_id" => "person_1" }], previous_page.page
      assert previous_page.next?
    end

    assert_equal({ "before" => "person_2" }.to_json, requests[1][:body])
  end

  def test_next_page_and_previous_page_return_nil_when_unavailable
    payload = page_payload(page: [{ "id" => 1 }])

    with_http_client_returning(status: 200, body: JSON.generate(payload)) do
      page = WebFunction::Request.execute("https://api.example.com/list-people")

      assert_nil page.next_page
      assert_nil page.previous_page
    end
  end

  def test_page_is_enumerable_over_items
    payload = page_payload(page: [{ "id" => 1 }, { "id" => 2 }])

    with_http_client_returning(status: 200, body: JSON.generate(payload)) do
      page = WebFunction::Request.execute("https://api.example.com/list-people")

      assert_equal([1, 2], page.map { |item| item["id"] })
      assert_equal 2, page.count
    end
  end

  def test_client_call_returns_page_for_paginated_endpoint
    package = WebFunction::Package.from_hash(
      "base_url" => "https://api.example.com/",
      "endpoints" => [
        { "name" => "list-people", "flags" => ["paginated"], "returns" => "object" },
      ],
    )
    client = WebFunction::Client.from_package(package)
    payload = page_payload(page: [{ "person_id" => "person_1" }], next_body: { "after" => "person_1" })

    with_http_client_returning(status: 200, body: JSON.generate(payload)) do
      result = client.list_people(filters: { first_name: "Joe" })

      assert_instance_of WebFunction::Page, result
      assert_equal [{ "person_id" => "person_1" }], result.page
    end
  end
end
