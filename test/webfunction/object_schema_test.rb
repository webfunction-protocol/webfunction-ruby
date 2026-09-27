# frozen_string_literal: true

require "test_helper"

class WebFunctionObjectSchemaTest < Minitest::Test
  def object_payload
    {
      "name" => "user",
      "arguments" => [
        { "name" => "id", "type" => "string" },
        { "name" => "email", "type" => "string.email" },
      ],
      "attributes" => [
        { "name" => "created_at", "type" => "string.datetime" },
      ],
    }
  end

  def test_from_hash_readers
    object = WebFunction::ObjectSchema.from_hash(object_payload)
    assert_equal "user", object.name
    assert_equal %w[id email], object.arguments.map(&:name)
    assert_equal %w[created_at], object.attributes.map(&:name)
  end

  def test_from_hash_returns_nil_when_invalid
    assert_nil WebFunction::ObjectSchema.from_hash("not a hash")
    assert_nil WebFunction::ObjectSchema.from_hash("arguments" => [])
  end

  def test_from_hash_defaults_members_to_empty
    object = WebFunction::ObjectSchema.from_hash("name" => "empty")
    assert_equal [], object.arguments
    assert_equal [], object.attributes
  end

  def test_argument_and_attribute_lookup
    object = WebFunction::ObjectSchema.from_hash(object_payload)
    assert_equal "id", object.argument("id").name
    assert_equal "id", object.argument(:id).name
    assert_nil object.argument("missing")
    assert_equal "created_at", object.attribute("created_at").name
    assert_equal "created_at", object.attribute(:created_at).name
    assert_nil object.attribute("missing")
  end

  def test_properties_resolves_by_context
    object = WebFunction::ObjectSchema.from_hash(object_payload)
    assert_equal object.arguments, object.properties(:arguments)
    assert_equal object.attributes, object.properties(:attributes)
  end

  def test_properties_raises_on_unknown_context
    object = WebFunction::ObjectSchema.from_hash(object_payload)
    assert_raises(ArgumentError) { object.properties(:bogus) }
  end

  def test_from_array_skips_invalid_entries
    entries = [object_payload, "not-a-hash", { "arguments" => [] }]
    objects = WebFunction::ObjectSchema.from_array(entries)
    assert_equal %w[user], objects.map(&:name)
  end

  def test_from_array_returns_empty_when_not_an_array
    assert_equal [], WebFunction::ObjectSchema.from_array(nil)
    assert_equal [], WebFunction::ObjectSchema.from_array("nope")
  end
end
