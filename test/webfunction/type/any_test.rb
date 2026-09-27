# frozen_string_literal: true

require "test_helper"

class WebFunctionTypeAnyTest < Minitest::Test
  Type = WebFunction::Type

  def test_readers
    assert_equal "any", Type.any.base_type
    assert_nil Type.any.refinement
  end

  def test_format_is_always_any
    assert_equal "any", Type.any.format
    assert_equal "any", Type.any.format(:compact)
    assert_equal "any", Type.any.format(:base)
    assert_equal "any", Type.any.to_s
  end

  def test_inspect
    assert_equal "#<any>", Type.any.inspect
  end

  def test_equality_and_hash
    assert_equal Type.any, Type.any
    refute_equal Type.any, Type.string
    assert_equal Type.any.hash, Type.any.hash
  end

  def test_objects_is_empty
    assert_equal [], Type.any.objects
  end

  def test_without_refinements_returns_self
    any = Type.any
    assert_same any, any.without_refinements
  end

  def test_valid_accepts_anything
    assert Type.any.valid?("string")
    assert Type.any.valid?(42)
    assert Type.any.valid?(nil)
    assert Type.any.valid?({ "a" => 1 })
    assert Type.any.valid?([1, 2, 3])
  end
end
