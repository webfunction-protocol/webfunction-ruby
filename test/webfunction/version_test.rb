# frozen_string_literal: true

require "test_helper"

class WebFunctionVersionTest < Minitest::Test
  def test_version_is_defined_and_semver_like
    refute_nil WebFunction::VERSION
    assert_match(/\A\d+\.\d+\.\d+/, WebFunction::VERSION)
  end
end
