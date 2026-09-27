# frozen_string_literal: true

require "test_helper"

class WebFunctionAttributeTest < Minitest::Test
  def hash_payload
    {
      "name" => "state",
      "type" => "array",
      "values" => %w[open closed],
      "flags" => [:nullable],
      "docs" => "Current state",
    }
  end

  def test_readers
    attribute = WebFunction::Attribute.from_hash(hash_payload)
    assert_equal "state", attribute.name
    assert_equal WebFunction::Type.array, attribute.type
    assert_equal %w[open closed], attribute.values
    assert_equal %w[nullable], attribute.flags
    assert_equal "Current state", attribute.docs
  end

  def test_type_is_parsed_into_a_type
    attribute = WebFunction::Attribute.from_hash("name" => "n", "type" => "string.email")
    assert_equal WebFunction::Type.string("email"), attribute.type
    assert_equal "string.email", attribute.type.to_s
  end

  def test_values_and_flags_empty_when_missing
    attribute = WebFunction::Attribute.from_hash("name" => "n", "type" => "string")
    assert_equal [], attribute.values
    assert_equal [], attribute.flags
  end

  def test_nullable
    nullable = WebFunction::Attribute.from_hash("name" => "n", "type" => "string", "flags" => %w[nullable])
    assert nullable.nullable?

    attribute = WebFunction::Attribute.from_hash("name" => "n", "type" => "string")
    refute attribute.nullable?
  end

  def test_docs_coerces_nil
    attribute = WebFunction::Attribute.from_hash("name" => "n", "type" => "string")
    assert_equal "", attribute.docs
  end

  def test_from_hash_returns_nil_when_invalid
    assert_nil WebFunction::Attribute.from_hash("not a hash")
    assert_nil WebFunction::Attribute.from_hash("type" => "string")
    assert_nil WebFunction::Attribute.from_hash("name" => "n")
  end
end
