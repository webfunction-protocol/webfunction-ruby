# frozen_string_literal: true

require "test_helper"

class WebFunctionDocumentedErrorTest < Minitest::Test
  def test_readers
    error = WebFunction::DocumentedError.from_hash("code" => "E_AUTH", "docs" => "Auth failed")
    assert_equal "E_AUTH", error.code
    assert_equal "Auth failed", error.docs
  end

  def test_docs_coerces_nil
    error = WebFunction::DocumentedError.from_hash("code" => "E")
    assert_equal "", error.docs
  end
end
