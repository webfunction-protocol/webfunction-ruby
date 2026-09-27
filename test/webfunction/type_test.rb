# frozen_string_literal: true

require "test_helper"

class WebFunctionTypeTest < Minitest::Test
  Type = WebFunction::Type

  def test_factories_build_expected_nodes
    assert_instance_of Type::Base, Type.string
    assert_instance_of Type::Base, Type.number
    assert_instance_of Type::Base, Type.object
    assert_instance_of Type::Base, Type.boolean
    assert_instance_of Type::Base, Type.null
    assert_instance_of Type::ArrayOf, Type.array
    assert_instance_of Type::Any, Type.any
  end

  def test_string_and_number_carry_refinements
    assert_equal "email", Type.string("email").refinement
    assert_equal "u32", Type.number("u32").refinement
    assert_nil Type.string.refinement
  end

  def test_array_defaults_to_array_of_any
    assert_equal Type.any, Type.array.of
    assert_equal Type.string, Type.array(Type.string).of
  end

  def test_union_collapses_single_member
    assert_equal Type.string, Type.union([Type.string])
  end

  def test_union_deduplicates_members
    union = Type.union([Type.string, Type.string, Type.number])
    assert_instance_of Type::Union, union
    assert_equal [Type.string, Type.number], union.members
  end

  def test_parse_nil_and_empty_yield_any
    assert_equal Type.any, Type.parse(nil)
    assert_equal Type.any, Type.parse([])
  end

  def test_parse_single_string
    assert_equal Type.string, Type.parse("string")
  end

  def test_parse_refined_string
    assert_equal Type.string("email"), Type.parse("string.email")
  end

  def test_parse_wraps_multiple_types_into_a_union
    assert_equal Type.union([Type.string, Type.number]), Type.parse(%w[string number])
  end

  def test_parse_unknown_type_is_dropped_and_falls_back_to_any
    assert_equal Type.any, Type.parse("integer")
    assert_equal Type.string, Type.parse(%w[integer string])
  end

  def test_detect_string_builds_base
    assert_equal Type.string, Type.detect("string")
  end

  def test_detect_array_builds_array_of_union
    assert_equal Type.array(Type.union([Type.string, Type.number])), Type.detect(%w[string number])
  end

  def test_detect_empty_array_builds_array_of_any
    assert_equal Type.array(Type.any), Type.detect([])
  end

  def test_detect_unknown_returns_nil
    assert_nil Type.detect(42)
    assert_nil Type.detect("integer")
  end

  def test_base_known_types
    assert_equal Type.boolean, Type.base("boolean")
    assert_equal Type.null, Type.base("null")
    assert_equal Type.any, Type.base("any")
    assert_equal Type.array, Type.base("array")
  end

  def test_base_object_keeps_refinement_as_name
    assert_equal Type.object("user"), Type.base("object.user")
    assert_equal "user", Type.base("object.user").refinement
  end

  def test_base_drops_unknown_refinements
    assert_equal Type.string, Type.base("string.bogus")
    assert_equal Type.number, Type.base("number.bogus")
  end

  def test_base_unknown_type_returns_nil
    assert_nil Type.base("integer")
  end
end
