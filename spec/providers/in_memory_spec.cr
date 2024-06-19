require "../spec_helper"

describe OpenFeature::Providers::InMemory do
  mem = OpenFeature::Providers::InMemory.new(OpenFeature::Metadata{
    "boolean" => true,
    "int"     => 1,
    "float"   => 2.2,
    "string"  => "test",
    "obj"     => OpenFeature::Structure{
      "test" => "bar",
    },
  })

  it "can resolve boolean" do
    r = mem.resolve_boolean_value("unknown", true).value
    r.should eq(true)
    r = mem.resolve_boolean_value("unknown", false).value
    r.should eq(false)
    r = mem.resolve_boolean_value("boolean", false).value
    r.should eq(true)
  end

  it "can resolve number" do
    r = mem.resolve_number_value("unknown", 1).value
    r.should eq(1)
    r = mem.resolve_number_value("int", 2).value
    r.should eq(1)
    r = mem.resolve_number_value("float", 3).value
    r.should eq(2.2)
  end

  it "can resolve object" do
    s = OpenFeature::Structure{
      "test" => "foo",
    }

    r = mem.resolve_object_value("unknown", s).value.as(OpenFeature::Structure)
    r["test"].should eq("foo")
    r = mem.resolve_object_value("obj", s).value.as(OpenFeature::Structure)
    r["test"].should eq("bar")
  end

  it "can resolve string" do
    r = mem.resolve_string_value("unknown", "as").value
    r.should eq("as")
    r = mem.resolve_string_value("string", "as").value
    r.should eq("test")
  end
end
