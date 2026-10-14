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
end