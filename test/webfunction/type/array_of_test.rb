# frozen_string_literal: true

require "test_helper"

class WebFunctionTypeArrayOfTest < Minitest::Test
  Type = WebFunction::Type

  def test_readers
    type = Type.array(Type.string)
    assert_equal "array", type.base_type
    assert_equal Type.string, type.of
    assert_nil type.refinement
  end

  def test_format
    type = Type.array(Type.string("email"))
    assert_equal "array<string.email>", type.format
    assert_equal "array<email>", type.format(:compact)
    assert_equal "array", type.format(:base)
  end

  def test_format_raises_on_unknown_format
    assert_raises(ArgumentError) { Type.array.format(:bogus) }
  end

  def test_to_s
    assert_equal "array<any>", Type.array.to_s
    assert_equal "array<string>", Type.array(Type.string).to_s
  end

  def test_inspect
    assert_equal "#<ArrayOf #<string>>", Type.array(Type.string).inspect
  end

  def test_equality_and_hash
    assert_equal Type.array(Type.string), Type.array(Type.string)
    refute_equal Type.array(Type.string), Type.array(Type.number)
    assert_equal Type.array(Type.string).hash, Type.array(Type.string).hash
  end

  def test_objects_delegates_to_element
    assert_equal ["user"], Type.array(Type.object("user")).objects
    assert_equal [], Type.array(Type.string).objects
  end

  def test_without_refinements_recurses
    assert_equal Type.array(Type.string), Type.array(Type.string("email")).without_refinements
  end

  def test_valid
    type = Type.array(Type.string)
    assert type.valid?(%w[a b])
    assert type.valid?([])
    refute type.valid?([1, "a"])
    refute type.valid?("not an array")
  end
end
