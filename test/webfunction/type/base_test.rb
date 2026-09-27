# frozen_string_literal: true

require "test_helper"

class WebFunctionTypeBaseTest < Minitest::Test
  Type = WebFunction::Type

  def test_readers
    type = Type.string("email")
    assert_equal "string", type.base_type
    assert_equal "email", type.refinement
  end

  def test_format
    assert_equal "string.email", Type.string("email").format
    assert_equal "string.email", Type.string("email").format(:default)
    assert_equal "email", Type.string("email").format(:compact)
    assert_equal "string", Type.string("email").format(:base)
    assert_equal "string", Type.string.format(:compact)
  end

  def test_format_raises_on_unknown_format
    assert_raises(ArgumentError) { Type.string.format(:bogus) }
  end

  def test_to_s_uses_default_format
    assert_equal "string.email", Type.string("email").to_s
    assert_equal "string", Type.string.to_s
  end

  def test_inspect
    assert_equal "#<string email>", Type.string("email").inspect
    assert_equal "#<string>", Type.string.inspect
  end

  def test_equality_and_hash
    assert_equal Type.string("email"), Type.string("email")
    refute_equal Type.string("email"), Type.string
    refute_equal Type.string, Type.number
    assert_equal Type.string("email").hash, Type.string("email").hash

    set = [Type.string("email"), Type.string("email"), Type.number].uniq
    assert_equal [Type.string("email"), Type.number], set
  end

  def test_objects
    assert_equal ["user"], Type.object("user").objects
    assert_equal [], Type.object.objects
    assert_equal [], Type.string.objects
  end

  def test_without_refinements
    assert_equal Type.string, Type.string("email").without_refinements

    plain = Type.string
    assert_same plain, plain.without_refinements
  end

  def test_valid_string
    assert Type.string.valid?("hello")
    refute Type.string.valid?(42)
    assert Type.string("email").valid?("a@b.co")
    refute Type.string("email").valid?("nope")
  end

  def test_valid_number
    assert Type.number.valid?(1)
    assert Type.number.valid?(1.5)
    refute Type.number.valid?("1")
    refute Type.number.valid?(Complex(1, 2))
    assert Type.number("u32").valid?(10)
    refute Type.number("u32").valid?(-1)
  end

  def test_valid_object_boolean_null
    assert Type.object.valid?({ "a" => 1 })
    refute Type.object.valid?([])
    assert Type.boolean.valid?(true)
    assert Type.boolean.valid?(false)
    refute Type.boolean.valid?("true")
    assert Type.null.valid?(nil)
    refute Type.null.valid?(false)
  end

  def test_number_refinement_validators
    assert Type.number("i32").valid?(-5)
    refute Type.number("i32").valid?(0x80000000)
    assert Type.number("timestamp").valid?(0)
    refute Type.number("timestamp").valid?(-1)
    refute Type.number("f64").valid?(Float::INFINITY)
  end

  def test_string_refinement_validators
    assert Type.string("date").valid?("2026-07-13")
    refute Type.string("date").valid?("13-07-2026")
    assert Type.string("uuid").valid?("123e4567-e89b-12d3-a456-426614174000")
    assert Type.string("url").valid?("https://webfunction.org")
    refute Type.string("url").valid?("not a url")
    assert Type.string("ipv4").valid?("127.0.0.1")
    refute Type.string("ipv4").valid?("::1")
    assert Type.string("ipv6").valid?("::1")
    assert Type.string("base64").valid?("aGVsbG8=")
    refute Type.string("base64").valid?("aGVsbG8")
  end
end
