# frozen_string_literal: true

require "test_helper"

class WebFunctionTypeUnionTest < Minitest::Test
  Type = WebFunction::Type

  def union
    Type.union([Type.string, Type.number])
  end

  def test_readers
    assert_equal [Type.string, Type.number], union.members
    assert_nil union.base_type
    assert_nil union.refinement
  end

  def test_format
    assert_equal "string | number", union.format
    assert_equal "string | number", union.format(:base)
    assert_equal "email | number", Type.union([Type.string("email"), Type.number]).format(:compact)
  end

  def test_to_s
    assert_equal "string | number", union.to_s
  end

  def test_inspect
    assert_equal "#<Union #<string> | #<number>>", union.inspect
  end

  def test_equality_and_hash
    assert_equal Type.union([Type.string, Type.number]), Type.union([Type.string, Type.number])
    refute_equal Type.union([Type.string, Type.number]), Type.union([Type.string, Type.boolean])
    assert_equal union.hash, Type.union([Type.string, Type.number]).hash
  end

  def test_objects_collects_from_members
    type = Type.union([Type.object("user"), Type.object("account"), Type.string])
    assert_equal %w[user account], type.objects
  end

  def test_without_refinements_recurses
    type = Type.union([Type.string("email"), Type.number("u32")])
    assert_equal Type.union([Type.string, Type.number]), type.without_refinements
  end

  def test_valid_matches_any_member
    assert union.valid?("hello")
    assert union.valid?(42)
    refute union.valid?(true)
  end
end
