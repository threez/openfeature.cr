require "./spec_helper"


class CaptureEvaluationContextProvider < OpenFeature::NoopProvider
  property last_ctx : OpenFeature::EvaluationContext?
  
  def resolve_boolean_value(flag_key : String,
      default : Bool = true,
      ctx : OpenFeature::EvaluationContext? = nil) : OpenFeature::ResolutionDetails(Bool)
    @last_ctx = ctx
    return super(flag_key, default, ctx)
  end
end

describe OpenFeature do
  describe "_value functions" do
    OpenFeature.provider = OpenFeature::NoopProvider.new
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
      default = Time.local
      obj = client.object_value("obj", default)
      obj.should eq(default)
    end
  end

  describe "EvaluationContext" do
    it "replaces the context according to the specification" do
      provider = CaptureEvaluationContextProvider.new
      OpenFeature.set_provider provider, domain: "ctx"

      # global context
      OpenFeature.global_context = OpenFeature::EvaluationContext.new do |cf|
        cf["location"] = "DE"
        cf["replace"] = 1
      end
  
      OpenFeature.transaction_context = OpenFeature::EvaluationContext.new("account-1") do |cf|
        cf["request-id"] = "12345"
        cf["replace"] = 2
      end
  
      OpenFeature.add_proc_hook before: OpenFeature::ProcStageHook.new { |ctx, hints|
        OpenFeature::EvaluationContext.new do |cf|
          cf["hook"] = "it"
          cf["replace"] = 5
        end
      }

      client_context = OpenFeature::EvaluationContext.new do |cf|
        cf["agent"] = "rest"
        cf["replace"] = 3
      end
      client = OpenFeature.client("ctx", context: client_context)

      invocation_context = OpenFeature::EvaluationContext.new("user-1") do |cf|
        cf["invocation"] = "v2_enabled"
        cf["replace"] = 4
      end
      v2_enabled = client.boolean_value("v2_enabled", true, context: invocation_context)
      v2_enabled.should eq(true)

      provider.last_ctx.should_not be_nil
      ctx = provider.last_ctx.not_nil!
      ctx.targeting_key.should eq("user-1")
      cf = ctx.custom_fields
      cf["request-id"].should eq("12345")
      cf["invocation"].should eq("v2_enabled")
      cf["hook"].should eq("it")
      cf["location"].should eq("DE")
      cf["agent"].should eq("rest")
      cf["replace"].should eq(5)
    end 
  end
end
