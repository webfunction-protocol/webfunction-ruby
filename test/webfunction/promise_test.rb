# frozen_string_literal: true

require "test_helper"

class WebFunctionPromiseTest < Minitest::Test
  def test_path_subscript_string_and_symbol_build_dot_paths
    path = WebFunction::Promise::Path.new("$[0]")
    assert_equal "$[0].name", path[:name].to_s
    assert_equal "$[0].name", path["name"].to_s
  end

  def test_path_subscript_integer_builds_index_paths
    path = WebFunction::Promise::Path.new("$[0]")
    assert_equal "$[0][2]", path[2].to_s
  end

  def test_path_subscript_rejects_non_string_symbol_integer
    path = WebFunction::Promise::Path.new("$[0]")
    assert_raises(ArgumentError) { path[1.5] }
  end

  def test_path_to_s
    assert_equal "$[1]", WebFunction::Promise::Path.new("$[1]").to_s
  end

  def test_path_to_json_serializes_path_string
    path = WebFunction::Promise::Path.new("$[0].x")
    assert_equal "\"$[0].x\"", path.to_json
  end

  def test_promise_value_raises_until_resolved
    pipeline = WebFunction::Pipeline.new("https://pipe.example/exec")
    promise = pipeline.add_step({})

    assert_raises(WebFunction::UnresolvedPromiseError) { promise.value }
    assert_equal "$[0]", promise.to_s
  end

  def test_promise_subscript_delegates_to_path_when_unresolved
    pipeline = WebFunction::Pipeline.new("https://pipe.example/exec")
    promise = pipeline.add_step({})
    assert_equal "$[0].id", promise[:id].to_s
  end

  def test_promise_resolve_runs_pipeline_and_returns_value
    pipeline = WebFunction::Pipeline.new("https://pipe.example/exec")
    promise = pipeline.add_step({ k: 1 })

    with_http_client_returning(status: 200, body: JSON.generate([{ "r" => 9 }])) do
      assert_equal({ "r" => 9 }, promise.resolve)
      assert_equal({ "r" => 9 }, promise.value)
    end
  end

  def test_promise_to_json_when_resolved
    pipeline = WebFunction::Pipeline.new("https://pipe.example/exec")
    promise = pipeline.add_step({})
    with_http_client_returning(status: 200, body: JSON.generate([42])) do
      promise.resolve
      assert_equal "42", promise.to_json
    end
  end

  def test_promise_to_json_when_unresolved_uses_path
    pipeline = WebFunction::Pipeline.new("https://pipe.example/exec")
    promise = pipeline.add_step({})
    assert_equal "\"$[0]\"", promise.to_json
  end

  def test_promise_subscript_after_resolve_delegates_to_value
    pipeline = WebFunction::Pipeline.new("https://pipe.example/exec")
    promise = pipeline.add_step({})
    with_http_client_returning(status: 200, body: JSON.generate([{ "items" => [1, 2] }])) do
      promise.resolve
      assert_equal [1, 2], promise["items"]
    end
  end
end
