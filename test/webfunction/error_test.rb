# frozen_string_literal: true

require "test_helper"

class WebFunctionErrorTest < Minitest::Test
  def test_error_stores_message_code_and_details
    error = WebFunction::Error.new("msg", code: "E1", details: { "k" => 1 })
    assert_equal "msg", error.message
    assert_equal "E1", error.code
    assert_equal({ "k" => 1 }, error.details)
  end

  def test_error_optional_fields_nil
    error = WebFunction::Error.new("only message")
    assert_equal "only message", error.message
    assert_equal "WFN_ERROR", error.code
    assert_nil error.details
  end

  def test_unresolved_promise_is_standard_error_subclass
    assert_operator WebFunction::UnresolvedPromiseError, :<, StandardError
  end
end
