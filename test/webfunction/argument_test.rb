# frozen_string_literal: true

require "test_helper"

class WebFunctionArgumentTest < Minitest::Test
  def hash_payload
    {
      "name" => "limit",
      "type" => "number",
      "group" => "pagination",
      "choices" => [10, 20],
      "flags" => [:required],
      "docs" => "Pagination limit",
    }
  end

  def test_readers
    argument = WebFunction::Argument.from_hash(hash_payload)
    assert_equal "limit", argument.name
    assert_equal WebFunction::Type.number, argument.type
    assert_equal "pagination", argument.group
    assert_equal [10, 20], argument.choices
    assert_equal %w[required], argument.flags
    assert_equal "Pagination limit", argument.docs
  end

  def test_type_is_parsed_into_a_type
    argument = WebFunction::Argument.from_hash("name" => "n", "type" => %w[string number])
    assert_equal WebFunction::Type.union([WebFunction::Type.string, WebFunction::Type.number]), argument.type
    assert_equal "string | number", argument.type.to_s
  end

  def test_choices_and_flags_empty_when_missing
    argument = WebFunction::Argument.from_hash("name" => "n", "type" => "string")
    assert_equal [], argument.choices
    assert_equal [], argument.flags
  end

  def test_required_and_optional
    required = WebFunction::Argument.from_hash("name" => "n", "type" => "string", "flags" => %w[required])
    assert required.required?
    refute required.optional?

    optional = WebFunction::Argument.from_hash("name" => "n", "type" => "string")
    refute optional.required?
    assert optional.optional?
  end

  def test_docs_coerces_nil
    argument = WebFunction::Argument.from_hash("name" => "n", "type" => "string")
    assert_equal "", argument.docs
  end

  def test_from_hash_returns_nil_when_invalid
    assert_nil WebFunction::Argument.from_hash("not a hash")
    assert_nil WebFunction::Argument.from_hash("type" => "string")
    assert_nil WebFunction::Argument.from_hash("name" => "n")
  end
end
