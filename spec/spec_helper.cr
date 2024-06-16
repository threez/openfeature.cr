require "spec"
require "../src/openfeature"
require "../src/openfeature/provider/*"

class CaptureEvaluationContextProvider < OpenFeature::NoopProvider
  property last_ctx : OpenFeature::EvaluationContext {
    OpenFeature::EvaluationContext.new
  }

  def resolve_boolean_value(flag_key : String,
                            default : Bool = true,
                            ctx : OpenFeature::EvaluationContext? = nil) : OpenFeature::ResolutionDetails(Bool)
    @last_ctx = ctx
    super(flag_key, default, ctx)
  end
end
