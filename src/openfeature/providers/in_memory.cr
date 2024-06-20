require "../provider"

module OpenFeature::Providers
  class InMemory < Provider
    getter flags : Metadata

    def initialize(@flags : Metadata = Metadata.new)
      super("InMemory")
      set_state(ProviderEvent::READY)
    end

    def flags=(new_flags : Metadata)
      @flags = new_flags
      details = ProviderEventDetails.new(new_flags.keys)
      emit_event(ProviderEvent::CONFIGURATION_CHANGED, details)
    end

    def resolve_boolean_value(flag_key : FlagKey,
                              default : Bool = true,
                              ctx : EvaluationContext? = nil) : ResolutionDetails
      resolve_value(flag_key, default, ctx)
    end

    def resolve_string_value(flag_key : FlagKey,
                             default : String = "",
                             ctx : EvaluationContext? = nil) : ResolutionDetails
      resolve_value(flag_key, default, ctx)
    end

    def resolve_number_value(flag_key : FlagKey,
                             default : Number = 0,
                             ctx : EvaluationContext? = nil) : ResolutionDetails
      resolve_value(flag_key, default, ctx)
    end

    def resolve_object_value(flag_key : FlagKey,
                             default : Structure,
                             ctx : EvaluationContext? = nil) : ResolutionDetails
      resolve_value(flag_key, default, ctx)
    end

    private def resolve_value(flag_key : FlagKey,
                              default,
                              ctx : EvaluationContext? = nil) : ResolutionDetails
      reason = Reason::STATIC
      value = @flags.fetch(flag_key) do
        reason = Reason::DEFAULT
        default
      end
      ResolutionDetails.new(value, reason: reason)
    end
  end
end
