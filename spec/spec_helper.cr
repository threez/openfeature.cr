require "spec"
require "../src/openfeature"
require "../src/openfeature/providers/*"
require "../src/openfeature/hooks/*"

class CaptureEvaluationContextProvider < OpenFeature::Providers::InMemory
  property last_ctx : OpenFeature::EvaluationContext do
    OpenFeature::EvaluationContext.new
  end

  def resolve_boolean_value(flag_key : OpenFeature::FlagKey,
                            default : Bool = true,
                            ctx : OpenFeature::EvaluationContext? = nil) : OpenFeature::ResolutionDetails
    @last_ctx = ctx
    super(flag_key, default, ctx)
  end
end
