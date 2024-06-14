require "./spec_helper"

describe OpenFeature do
  OpenFeature.set_provider(OpenFeature::NoopProvider.new)
  client = OpenFeature.get_client("app")

  it "get_boolean_value" do
    v2_enabled = client.get_boolean_value("v2_enabled", true)
    v2_enabled.should eq(true)
  end

  it "get_string_value" do
    app_name = client.get_string_value("app_name", "default")
    app_name.should eq("default")
  end

  it "get_number_value" do
    app_id = client.get_number_value("app_id", 0)
    app_id.should eq(0)

    app_version = client.get_number_value("app_version", 0.0)
    app_version.should eq(0.0)
  end

  it "get_object_value" do
    default = Time.local
    obj = client.get_object_value("obj", default)
    obj.should eq(default)
  end
end
