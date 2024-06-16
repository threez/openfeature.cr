require "./spec_helper"

describe OpenFeature do
  describe "_value functions" do
    OpenFeature.provider = OpenFeature::Providers::Noop.new
    client = OpenFeature.client("app")

    it "boolean_value" do
      v2_enabled = client.boolean_value("v2_enabled", true)
      v2_enabled.should eq(true)
    end

    it "string_value" do
      app_name = client.string_value("app_name", "default")
      app_name.should eq("default")
    end

    it "number_value" do
      app_id = client.number_value("app_id", 0)
      app_id.should eq(0)

      app_version = client.number_value("app_version", 0.0)
      app_version.should eq(0.0)
    end

    it "object_value" do
      default = OpenFeature::CustomFields.new
      default["foo"] = "bar"
      obj = client.object_value("obj", default)
      obj.should eq(default)
    end
  end

  describe "EvaluationContext" do
    it "replaces the context according to the specification" do
      provider = CaptureEvaluationContextProvider.new
      OpenFeature.set_provider provider, domain: "ctx"

      # global context
      OpenFeature.global_context = OpenFeature::EvaluationContext.new do |custom_fields|
        custom_fields["location"] = "DE"
        custom_fields["replace"] = 1
      end

      OpenFeature.transaction_context = OpenFeature::EvaluationContext.new("account-1") do |custom_fields|
        custom_fields["request-id"] = "12345"
        custom_fields["replace"] = 2
      end

      OpenFeature.add_proc_hook before: OpenFeature::BeforeStageHook.new { |_, _|
        OpenFeature::EvaluationContext.new do |custom_fields|
          custom_fields["ghook"] = "it"
          custom_fields["replace"] = 5
        end
      }

      client_context = OpenFeature::EvaluationContext.new do |custom_fields|
        custom_fields["agent"] = "rest"
        custom_fields["replace"] = 3
      end
      client = OpenFeature.client("ctx", context: client_context)

      client.add_proc_hook before: OpenFeature::BeforeStageHook.new { |_, _|
        OpenFeature::EvaluationContext.new do |custom_fields|
          custom_fields["chook"] = "it"
          custom_fields["replace"] = 6
        end
      }

      invocation_context = OpenFeature::EvaluationContext.new("user-1") do |custom_fields|
        custom_fields["invocation"] = "v2_enabled"
        custom_fields["replace"] = 4
      end

      options = OpenFeature::EvaluationOptions.new
      options.add_proc_hook before: OpenFeature::BeforeStageHook.new { |_, _|
        OpenFeature::EvaluationContext.new do |custom_fields|
          custom_fields["ihook"] = "it"
          custom_fields["replace"] = 7
        end
      }

      v2_enabled = client.boolean_value("v2_enabled", true,
        context: invocation_context,
        options: options)
      v2_enabled.should eq(true)

      provider.last_ctx.should_not be_nil
      ctx = provider.last_ctx
      ctx.targeting_key.should eq("user-1")
      custom_fields = ctx.custom_fields
      custom_fields["request-id"].should eq("12345")
      custom_fields["invocation"].should eq("v2_enabled")
      custom_fields["ghook"].should eq("it")
      custom_fields["chook"].should eq("it")
      custom_fields["ihook"].should eq("it")
      custom_fields["location"].should eq("DE")
      custom_fields["agent"].should eq("rest")
      custom_fields["replace"].should eq(7)
    end
  end
end
