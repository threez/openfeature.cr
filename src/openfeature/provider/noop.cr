require "../provider"

module OpenFeature
  class NoopProvider < Provider
    def initialize
      super("noop")
      @state = ProviderEvents::READY
    end

    def resolve_boolean_value(flag_key : String,
        default : Bool = true,
        ctx : EvaluationContext? = nil) : ResolutionDetails(Bool)
      return ResolutionDetails(Bool).new(default, reason: Reason::STATIC)
    end

    def resolve_string_value(flag_key : String,
      default : String = "",
      ctx : EvaluationContext? = nil) : ResolutionDetails(String)
      return ResolutionDetails(String).new(default, reason: Reason::STATIC)
    end

    def resolve_number_value(flag_key : String,
      default : Number = 0,
      ctx : EvaluationContext? = nil) : ResolutionDetails(Number)
      return ResolutionDetails(Number).new(default, reason: Reason::STATIC)
    end

    def resolve_object_value(flag_key : String,
      default = nil,
      ctx : EvaluationContext? = nil) : ResolutionDetails
      return ResolutionDetails.new(default, reason: Reason::STATIC)
    end
  end
end
