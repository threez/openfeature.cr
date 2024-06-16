require "spec"
require "../src/openfeature"
require "../src/openfeature/providers/*"
require "../src/openfeature/hooks/*"

class CaptureEvaluationContextProvider < OpenFeature::Providers::Noop
  property last_ctx : OpenFeature::EvaluationContext {
    OpenFeature::EvaluationContext.new
  }

  def resolve_boolean_value(flag_key : OpenFeature::FlagKey,
                            default : Bool = true,
                            ctx : OpenFeature::EvaluationContext? = nil) : OpenFeature::ResolutionDetails
    @last_ctx = ctx
    super(flag_key, default, ctx)
  end
end
