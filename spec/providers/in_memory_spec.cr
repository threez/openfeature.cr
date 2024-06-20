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
    r = mem.resolve_boolean_value("unknown", true)
    r.reason.should eq(OpenFeature::Reason::DEFAULT)
    r.value.should eq(true)

    r = mem.resolve_boolean_value("unknown", false)
    r.reason.should eq(OpenFeature::Reason::DEFAULT)
    r.value.should eq(false)

    r = mem.resolve_boolean_value("boolean", false)
    r.reason.should eq(OpenFeature::Reason::STATIC)
    r.value.should eq(true)
  end

  it "can resolve number" do
    r = mem.resolve_number_value("unknown", 1)
    r.reason.should eq(OpenFeature::Reason::DEFAULT)
    r.value.should eq(1)

    r = mem.resolve_number_value("int", 2)
    r.reason.should eq(OpenFeature::Reason::STATIC)
    r.value.should eq(1)

    r = mem.resolve_number_value("float", 3)
    r.reason.should eq(OpenFeature::Reason::STATIC)
    r.value.should eq(2.2)
  end

  it "can resolve object" do
    s = OpenFeature::Structure{
      "test" => "foo",
    }

    r = mem.resolve_object_value("unknown", s)
    r.reason.should eq(OpenFeature::Reason::DEFAULT)
    r.value.as(OpenFeature::Structure)["test"].should eq("foo")

    r = mem.resolve_object_value("obj", s)
    r.reason.should eq(OpenFeature::Reason::STATIC)
    r.value.as(OpenFeature::Structure)["test"].should eq("bar")
  end

  it "can resolve string" do
    r = mem.resolve_string_value("unknown", "as")
    r.reason.should eq(OpenFeature::Reason::DEFAULT)
    r.value.should eq("as")

    r = mem.resolve_string_value("string", "as")
    r.reason.should eq(OpenFeature::Reason::STATIC)
    r.value.should eq("test")
  end
end
