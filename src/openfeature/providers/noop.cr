require "../provider"

module OpenFeature::Providers
  class Noop < Provider
    def initialize
      super("noop")
      set_state(ProviderEvent::READY)
    end

    def resolve_boolean_value(flag_key : FlagKey,
                              default : Bool = true,
                              ctx : EvaluationContext? = nil) : ResolutionDetails
      ResolutionDetails.new(default, reason: Reason::STATIC)
    end

    def resolve_string_value(flag_key : FlagKey,
                             default : String = "",
                             ctx : EvaluationContext? = nil) : ResolutionDetails
      ResolutionDetails.new(default, reason: Reason::STATIC)
    end

    def resolve_number_value(flag_key : FlagKey,
                             default : Number = 0,
                             ctx : EvaluationContext? = nil) : ResolutionDetails
      ResolutionDetails.new(default, reason: Reason::STATIC)
    end

    def resolve_object_value(flag_key : FlagKey,
                             default : CustomFields,
                             ctx : EvaluationContext? = nil) : ResolutionDetails
      ResolutionDetails.new(default, reason: Reason::STATIC)
    end
  end
end
