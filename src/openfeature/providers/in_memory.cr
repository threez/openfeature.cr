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
      value = @flags.fetch(flag_key, default)
      ResolutionDetails.new(value, reason: Reason::STATIC)
    end

    def resolve_string_value(flag_key : FlagKey,
                             default : String = "",
                             ctx : EvaluationContext? = nil) : ResolutionDetails
      value = @flags.fetch(flag_key, default)
      ResolutionDetails.new(value, reason: Reason::STATIC)
    end

    def resolve_number_value(flag_key : FlagKey,
                             default : Number = 0,
                             ctx : EvaluationContext? = nil) : ResolutionDetails
      value = @flags.fetch(flag_key, default)
      ResolutionDetails.new(value, reason: Reason::STATIC)
    end

    def resolve_object_value(flag_key : FlagKey,
                             default : Structure,
                             ctx : EvaluationContext? = nil) : ResolutionDetails
      value = @flags.fetch(flag_key, default)
      ResolutionDetails.new(value, reason: Reason::STATIC)
    end
  end
end
