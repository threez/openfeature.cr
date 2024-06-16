require "../provider"

module OpenFeature::Providers
  class Noop < Provider
    def initialize
      super("noop")
      @state = ProviderEvents::READY
    end

    def resolve_boolean_value(flag_key : String,
                              default : Bool = true,
                              ctx : EvaluationContext? = nil) : ResolutionDetails(Bool)
      ResolutionDetails(Bool).new(default, reason: Reason::STATIC)
    end

    def resolve_string_value(flag_key : String,
                             default : String = "",
                             ctx : EvaluationContext? = nil) : ResolutionDetails(String)
      ResolutionDetails(String).new(default, reason: Reason::STATIC)
    end

    def resolve_number_value(flag_key : String,
                             default : Number = 0,
                             ctx : EvaluationContext? = nil) : ResolutionDetails(Number)
      ResolutionDetails(Number).new(default, reason: Reason::STATIC)
    end

    def resolve_object_value(flag_key : String,
                             default = nil,
                             ctx : EvaluationContext? = nil) : ResolutionDetails
      ResolutionDetails.new(default, reason: Reason::STATIC)
    end
  end
end
