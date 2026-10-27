# frozen_string_literal: true

require "test_helper"

class WebFunctionTypeGenericsTest < Minitest::Test
  Type = WebFunction::Type

  def fmt(raw)
    Type.parse(raw).to_s
  end

  def test_existing_forms_are_unchanged
    assert_equal "string", fmt("string")
    assert_equal "string.email", fmt("string.email")
    assert_equal "object.user", fmt("object.user")
    assert_equal "string | null", fmt(["string", "null"])
    assert_equal "array<string>", fmt([["string"]])
    assert_equal "array<object.person | null>", fmt([["object.person", "null"]])
    assert_equal "array<any> | array<object.person>", fmt(["array", ["object.person"]])
    assert_equal "any", fmt(nil)
  end

  def test_single_application
    type = Type.parse({ "object.list" => "object.user" })

    assert_equal "object.list<object.user>", type.to_s
    assert_equal "object", type.base_type
    assert_equal "list", type.refinement
    assert_equal "object.user", type.arg.to_s
    assert_equal "list", type.format(:compact)
    assert_equal "object", type.format(:base)
    assert type.valid?({})
    refute type.valid?("nope")
  end

  def test_union_nested_and_array_arguments
    assert_equal "object.list<object.user | null>", fmt({ "object.list" => ["object.user", "null"] })
    assert_equal "object.page<object.page<object.user>>", fmt({ "object.page" => { "object.page" => "object.user" } })
    assert_equal "object.list<array<string>>", fmt({ "object.list" => [["string"]] })
    assert_equal ["page", "user"], Type.parse({ "object.page" => { "object.page" => "object.user" } }).objects
  end

  def test_applications_inside_unions_and_arrays
    assert_equal "object.list<object.user> | null", fmt([{ "object.list" => "object.user" }, "null"])
    assert_equal "array<object.list<object.user>>", fmt([[{ "object.list" => "object.user" }]])
    assert_equal "array<object.list<object.user> | null>", fmt([[{ "object.list" => "object.user" }, "null"]])
    assert_equal "object.list<object.pair<number> | null>",
      fmt({ "object.list" => [{ "object.pair" => "number" }, "null"] })
  end

  def test_equality_includes_the_argument
    list_of_user = Type.parse({ "object.list" => "object.user" })

    assert_equal list_of_user, Type.parse({ "object.list" => "object.user" })
    assert_equal list_of_user.hash, Type.parse({ "object.list" => "object.user" }).hash
    refute_equal list_of_user, Type.parse({ "object.list" => "string" })
    assert_equal "object.list<string> | object.list<number>",
      fmt([{ "object.list" => "string" }, { "object.list" => "number" }])
    assert_equal "object.list<string>", fmt([{ "object.list" => "string" }, { "object.list" => "string" }])
  end

  def test_malformed_applications_resolve_to_any_with_the_reason
    {
      {} => Type::MALFORMED_KEY_COUNT,
      { "object.a" => "string", "object.b" => "string" } => Type::MALFORMED_KEY_COUNT,
      { "string" => "object.user" } => Type::MALFORMED_KEY_PREFIX,
      { "list" => "object.user" } => Type::MALFORMED_KEY_PREFIX,
      { "object." => "string" } => Type::MALFORMED_KEY_PREFIX,
      { "object.list" => 5 } => Type::MALFORMED_ARGUMENT,
      { "object.list" => true } => Type::MALFORMED_ARGUMENT,
    }.each do |raw, reason|
      type = Type.parse(raw)

      assert_equal "any", type.to_s, raw.inspect
      assert_equal reason, type.malformed, raw.inspect
      assert type.valid?("anything"), raw.inspect
    end
  end

  def test_malformed_entry_in_a_union_is_kept_as_any
    type = Type.parse([{ "string" => "x" }, "null"])

    assert_equal "any | null", type.to_s
    assert_equal Type::MALFORMED_KEY_PREFIX, type.members.first.malformed
    assert_nil Type.any.malformed
  end

  def test_type_parameter_resolves_to_any
    assert_equal "any", fmt("T")
    assert_equal "array<any>", fmt([["T"]])
    assert_equal "any | null", fmt(["T", "null"])
    assert Type.parse("T").valid?("anything")
  end

  def test_type_parameter_is_marked_for_tooling
    assert_predicate Type.parse("T"), :param?
    assert_predicate Type.parse([["T"]]).of, :param?
    assert_predicate Type.parse(["T", "null"]).members.first, :param?
    refute_predicate Type.parse("any"), :param?
    refute_predicate Type.any, :param?
    assert_instance_of Type::Base, Type.parse("object.T")
    assert_equal "object.T", fmt("object.T")
  end

  def test_package_with_generics_loads
    package = WebFunction::Package.from_hash(
      {
        "base_url" => "https://api.example.com/",
        "endpoints" => [
          {
            "name" => "list-users",
            "returns" => { "object.list" => "object.user" },
            "arguments" => [{ "name" => "filter", "type" => [{ "object.pair" => "string" }, "null"] }],
          },
          { "name" => "broken", "returns" => {}, "arguments" => [] },
        ],
        "objects" => [
          {
            "name" => "list",
            "attributes" => [
              { "name" => "total", "type" => "number" },
              { "name" => "items", "type" => [["T"]] },
            ],
          },
        ],
      },
    )

    endpoint = package.endpoint("list-users")

    assert_equal "object.list<object.user>", endpoint.returns.to_s
    assert_equal "object.pair<string> | null", endpoint.argument("filter").type.to_s
    assert_equal "any", package.endpoint("broken").returns.to_s
    assert_equal "array<any>", package.object("list", context: :attributes).attribute("items").type.to_s
  end

  # { "array" => X } is the canonical way to write an array of X; it must read like the legacy [[X]].
  ARRAY_APPLICATION_PAIRS = [
    [{ "array" => "string" }, [["string"]]],
    [{ "array" => "object.user" }, [["object.user"]]],
    [{ "array" => ["string", "null"] }, [["string", "null"]]],
    [{ "array" => "T" }, [["T"]]],
    [{ "array" => { "array" => "string" } }, [[["string"]]]],
    [{ "array" => { "object.page" => "object.user" } }, [[{ "object.page" => "object.user" }]]],
    [{ "object.page" => { "array" => "object.user" } }, { "object.page" => [["object.user"]] }],
    [[{ "array" => "string" }, "null"], [["string"], "null"]],
  ].freeze

  def test_array_application_reads_like_the_legacy_form
    ARRAY_APPLICATION_PAIRS.each do |application, legacy|
      a = Type.parse(application)
      l = Type.parse(legacy)

      assert_equal l, a, application.inspect
      assert_equal l.to_s, a.to_s, application.inspect
      assert_equal l.format(:base), a.format(:base), application.inspect
      assert_equal l.format(:compact), a.format(:compact), application.inspect
      assert_equal l.objects, a.objects, application.inspect
    end
  end

  def test_array_application_formats
    assert_equal "array<string>", fmt({ "array" => "string" })
    assert_equal "array<object.user>", fmt({ "array" => "object.user" })
    assert_equal "array<string | number>", fmt({ "array" => ["string", "number"] })
    assert_equal "array<array<string>>", fmt({ "array" => { "array" => "string" } })
    assert_equal "array<object.page<object.user>>", fmt({ "array" => { "object.page" => "object.user" } })
    assert_equal "object.page<array<object.user>>", fmt({ "object.page" => { "array" => "object.user" } })
    assert_equal "array<any>", fmt({ "array" => "T" })
    assert_equal "array<string> | null", fmt([{ "array" => "string" }, "null"])
    assert_equal "array<any> | array<string>", fmt(["array", { "array" => "string" }])
  end

  def test_array_application_shape
    type = Type.parse({ "array" => "object.user" })

    assert_kind_of WebFunction::Type::ArrayOf, type
    assert_equal "array", type.base_type
    assert_equal "object.user", type.of.to_s
    assert_equal "array", type.format(:base)
    assert Type.parse({ "array" => "T" }).of.param?
  end

  def test_array_application_objects
    assert_equal ["user"], Type.parse({ "array" => "object.user" }).objects
    assert_equal ["page", "user"], Type.parse({ "array" => { "object.page" => "object.user" } }).objects
    assert_equal ["page", "user"], Type.parse({ "object.page" => { "array" => "object.user" } }).objects
    assert_equal ["user"], Type.parse({ "array" => { "array" => "object.user" } }).objects
  end

  def test_array_application_validates
    strings = Type.parse({ "array" => "string" })

    assert strings.valid?(["a", "b"])
    assert strings.valid?([])
    refute strings.valid?([1])
    refute strings.valid?("a")
    refute strings.valid?(nil)

    mixed = Type.parse({ "array" => ["string", "number"] })

    assert mixed.valid?(["a", 1])
    refute mixed.valid?([true])

    nested = Type.parse({ "array" => { "array" => "number" } })

    assert nested.valid?([[1], []])
    refute nested.valid?([["a"]])
  end

  def test_malformed_array_applications_stay_malformed
    {
      { "array" => "string", "object.a" => "string" } => Type::MALFORMED_KEY_COUNT,
      { "array" => 5 } => Type::MALFORMED_ARGUMENT,
      { "array" => true } => Type::MALFORMED_ARGUMENT,
      { "arrays" => "string" } => Type::MALFORMED_KEY_PREFIX,
      { "array.x" => "string" } => Type::MALFORMED_KEY_PREFIX,
      { "Array" => "string" } => Type::MALFORMED_KEY_PREFIX,
    }.each do |raw, reason|
      type = Type.parse(raw)

      assert_equal "any", type.to_s, raw.inspect
      assert_equal reason, type.malformed, raw.inspect
      assert type.valid?("anything"), raw.inspect
    end
  end

  # Spec: a union of one entry is that entry. The parser already collapses it; these pin it.
  def test_union_of_one_entry_is_that_entry
    assert_equal Type.parse("string"), Type.parse(["string"])
    assert_equal "email", Type.parse(["string.email"]).format(:compact)
    assert_equal "string.email", fmt(["string.email"])
    assert Type.parse(["T"]).param?
    assert_equal Type.parse({ "array" => "string" }), Type.parse([{ "array" => "string" }])
    assert_equal Type.parse({ "object.list" => "object.user" }), Type.parse([{ "object.list" => "object.user" }])
    # The legacy array shorthand is not a one-entry union: [["x"]] is still an array of x.
    assert_kind_of WebFunction::Type::ArrayOf, Type.parse([["string"]])
    assert_kind_of WebFunction::Type::Union, Type.parse(["string", "null"])
  end

  def test_package_with_array_applications_loads
    package = WebFunction::Package.from_hash(
      {
        "base_url" => "https://api.example.com/",
        "endpoints" => [{ "name" => "get-comments", "returns" => { "array" => "object.comment" }, "arguments" => [] }],
        "objects" => [
          {
            "name" => "comment",
            "attributes" => [
              { "name" => "id", "type" => "string.uuid" },
              { "name" => "message", "type" => "string" },
              { "name" => "replies", "type" => { "array" => "object.comment" } },
            ],
          },
        ],
      },
    )

    assert_equal "array<object.comment>", package.endpoint("get-comments").returns.to_s
    assert_equal "array<object.comment>", package.object("comment", context: :attributes).attribute("replies").type.to_s
  end
end