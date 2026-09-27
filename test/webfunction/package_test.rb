# frozen_string_literal: true

require "test_helper"

class WebFunctionPackageTest < Minitest::Test
  def sample_package
    {
      "base_url" => "https://api.webfunction.com/",
      "name" => "Web Function",
      "flags" => %w[alpha beta],
      "docs" => "Package docs",
      "endpoints" => [
        { "name" => "hello", "returns" => "object", "docs" => "Say hi" },
        "not-a-hash",
        { "docs" => "missing name" },
      ],
      "errors" => [
        { "code" => "NOT_FOUND", "docs" => "Missing" },
        "bad",
        { "docs" => "no code" },
      ],
    }
  end

  def test_accessors
    package = WebFunction::Package.from_hash(sample_package)
    assert_equal "https://api.webfunction.com/", package.base_url
    assert_equal "Web Function", package.name
    assert_equal "Package docs", package.docs
  end

  def test_flags_empty_when_missing_or_not_array
    assert_equal [], WebFunction::Package.from_hash({}).flags
    assert_equal [], WebFunction::Package.from_hash("flags" => {}).flags
  end

  def test_flags_returns_array_from_payload
    package = WebFunction::Package.from_hash("flags" => %w[x y])
    assert_equal %w[x y], package.flags
  end

  def test_endpoints_skips_invalid_entries
    package = WebFunction::Package.from_hash(sample_package)
    names = package.endpoints.compact.map(&:name)
    assert_equal ["hello"], names
  end

  def test_endpoints_empty_when_missing_or_not_array
    assert_equal [], WebFunction::Package.from_hash({}).endpoints
    assert_equal [], WebFunction::Package.from_hash("endpoints" => {}).endpoints
  end

  def test_errors_skips_invalid_entries
    package = WebFunction::Package.from_hash(sample_package)
    codes = package.errors.compact.map(&:code)
    assert_equal ["NOT_FOUND"], codes
  end

  def test_errors_empty_when_missing_or_not_array
    assert_equal [], WebFunction::Package.from_hash({}).errors
    assert_equal [], WebFunction::Package.from_hash("errors" => {}).errors
  end

  def test_docs_coerces_to_string
    assert_equal "", WebFunction::Package.from_hash({}).docs
    assert_equal "123", WebFunction::Package.from_hash("docs" => 123).docs
  end

  def package_with_objects
    WebFunction::Package.from_hash(
      "base_url" => "https://api.webfunction.com/",
      "objects" => [
        {
          "name" => "user",
          "arguments" => [{ "name" => "id", "type" => "string" }],
          "attributes" => [{ "name" => "email", "type" => "string.email" }],
        },
        { "name" => "input_only", "arguments" => [{ "name" => "q", "type" => "string" }] },
      ],
    )
  end

  def test_objects_readers
    package = package_with_objects
    assert_equal %w[user input_only], package.objects.map(&:name)
  end

  def test_object_resolves_when_context_has_members
    package = package_with_objects
    assert_equal "user", package.object("user", context: :arguments).name
    assert_equal "user", package.object("user", context: :attributes).name
    assert_equal "user", package.object(:user, context: :arguments).name
  end

  def test_object_returns_nil_when_context_has_no_members
    package = package_with_objects
    assert_nil package.object("input_only", context: :attributes)
    assert_equal "input_only", package.object("input_only", context: :arguments).name
  end

  def test_object_returns_nil_when_missing
    assert_nil package_with_objects.object("missing", context: :arguments)
  end

  def test_object_raises_on_unknown_context
    assert_raises(ArgumentError) { package_with_objects.object("user", context: :bogus) }
  end

  def test_objects_empty_when_missing_or_not_array
    assert_equal [], WebFunction::Package.from_hash({}).objects
    assert_equal [], WebFunction::Package.from_hash("objects" => {}).objects
  end
end
