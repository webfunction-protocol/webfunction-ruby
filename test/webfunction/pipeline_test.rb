# frozen_string_literal: true

require "test_helper"

class WebFunctionPipelineTest < Minitest::Test
  def test_add_step_returns_promise_with_stable_path_tokens
    pipeline = WebFunction::Pipeline.new("https://pipe.example/exec")
    p0 = pipeline.add_step({ url: "https://a", headers: {}, body: {} })
    p1 = pipeline.add_step({ url: "https://b", headers: {}, body: {} })

    assert_instance_of WebFunction::Promise, p0
    assert_instance_of WebFunction::Promise, p1
    assert_equal "$[0]", p0.to_s
    assert_equal "$[1]", p1.to_s
  end

  def test_execute_all_assigns_promise_values_and_resets
    pipeline = WebFunction::Pipeline.new("https://pipe.example/exec")
    p0 = pipeline.add_step({ step: 0 })
    p1 = pipeline.add_step({ step: 1 })

    with_http_client_returning(status: 200, body: JSON.generate([{ "a" => 1 }, { "b" => 2 }])) do
      out = pipeline.execute(returns: :all)
      assert_equal [{ "a" => 1 }, { "b" => 2 }], out
      assert_equal({ "a" => 1 }, p0.value)
      assert_equal({ "b" => 2 }, p1.value)
    end

    assert_equal({ "a" => 1 }, p0.value)
    assert_equal({ "b" => 2 }, p1.value)
  end

  def test_execute_last_sets_last_promise_only
    pipeline = WebFunction::Pipeline.new("https://pipe.example/exec")
    pipeline.add_step({ step: 0 })
    p1 = pipeline.add_step({ step: 1 })

    with_http_client_returning(status: 200, body: JSON.generate({ "last" => true })) do
      out = pipeline.execute(returns: :last)
      assert_equal({ "last" => true }, out)
      assert_equal({ "last" => true }, p1.value)
    end
  end

  def test_execute_custom_returns_passes_through
    pipeline = WebFunction::Pipeline.new("https://pipe.example/exec")
    pipeline.add_step({})

    with_http_client_returning(status: 200, body: JSON.generate("scalar")) do
      out = pipeline.execute(returns: "$[0].x")
      assert_equal "scalar", out
    end
  end

  def test_reset_clears_steps_so_fresh_add_step_restarts_indices
    pipeline = WebFunction::Pipeline.new("https://pipe.example/exec")
    pipeline.add_step({})
    pipeline.reset!
    p = pipeline.add_step({})
    assert_equal "$[0]", p.to_s
  end
end
