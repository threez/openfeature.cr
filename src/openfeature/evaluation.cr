require "./hook"

# :nodoc:
class Fiber
  # :nodoc:
  # Transaction context is a container for transaction-specific evaluation context
  # (e.g. user id, user agent, IP). Transaction context can be set where specific data
  # is available (e.g. an auth service or request handler)
  property openfeature_transaction_context : OpenFeature::EvaluationContext?
end

module OpenFeature
  @@context : EvaluationContext?

  def self.global_context=(context ctx : EvaluationContext)
    @@context = ctx
  end

  def self.global_context : EvaluationContext?
    @@context
  end

  def self.transaction_context=(ctx : EvaluationContext)
    Fiber.current.openfeature_transaction_context = ctx
  end

  # retuerns the current transaction context or a new context without content
  def self.transaction_context : EvaluationContext?
    Fiber.current.openfeature_transaction_context
  end

  enum Reason
    # The resolved value is static (no dynamic evaluation).
    STATIC
    # The resolved value fell back to a pre-configured value (no dynamic evaluation occurred or dynamic evaluation yielded no result).
    DEFAULT
    # The resolved value was the result of a dynamic evaluation, such as a rule or specific user-targeting.
    TARGETING_MATCH
    # The resolved value was the result of pseudorandom assignment.
    SPLIT
    # The resolved value was retrieved from cache.
    CACHED
    # The resolved value was the result of the flag being disabled in the management system.
    DISABLED
    # The reason for the resolved value could not be determined.
    UNKNOWN
    # The resolved value is non-authoritative or possibly out of date
    STALE
    # The resolved value was the result of an error.
    ERROR
  end

  # The evaluation context provides ambient information for the purposes
  # of flag evaluation. Contextual data may be used as the basis for targeting,
  # including rule-based evaluation, overrides for specific subjects, or
  # fractional flag evaluation.
  #
  # The context might contain information about the end-user, the application,
  # the host, or any other ambient data that might be useful in flag evaluation.
  # For example, a flag system might define rules that return a specific value
  # based on the user's email address, locale, or the time of day. The context
  # provides this information. The context can be optionally provided at
  # evaluation, and mutated in before hooks.
  class EvaluationContext
    # The targeting key uniquely identifies the subject (end-user, or client
    # service) of a flag evaluation. Providers may require this field for
    # fractional flag evaluation, rules, or overrides targeting specific users.
    # Such providers may behave unpredictably if a targeting key is not
    # specified at flag resolution.
    property targeting_key : TargetingKey?

    property custom_fields : CustomFields

    def initialize(*, @targeting_key : String? = nil,
                   @custom_fields : CustomFields = CustomFields.new)
    end

    def initialize(@targeting_key : String? = nil, &)
      custom_fields = CustomFields.new
      yield(custom_fields)
      @custom_fields = custom_fields
    end

    def merge(other : EvaluationContext) : EvaluationContext
      EvaluationContext.new(targeting_key: other.targeting_key || @targeting_key,
        custom_fields: @custom_fields.merge(other.custom_fields))
    end

    # Any fields defined in the transaction evaluation context will overwrite duplicate
    # fields defined in the global evaluation context, any fields defined in the client
    # evaluation context will overwrite duplicate fields defined in the transaction
    # evaluation context, and fields defined in the invocation evaluation context will
    # overwrite duplicate fields defined globally or on the client. Any resulting
    # evaluation context from a before hook will overwrite duplicate fields defined
    # globally, on the client, or in the invocation.
    def self.merged(*, global : EvaluationContext? = OpenFeature.global_context,
                    transaction : EvaluationContext? = OpenFeature.transaction_context,
                    client : EvaluationContext? = nil,
                    invocation : EvaluationContext? = nil) : EvaluationContext
      root = global || EvaluationContext.new
      root = root.merge(transaction) unless transaction.nil?
      root = root.merge(client) unless client.nil?
      root = root.merge(invocation) unless invocation.nil?
      root
    end
  end

  # Additional options that allow to define hooks and hook options for an
  # invocation.
  class EvaluationOptions
    property hooks : Array(Hook)
    property hook_hints : HookHints { HookHints.new }

    def initialize(@hook_hints : HookHints? = nil)
      @hooks = Array(Hook).new
    end

    def initialize(@hooks : Array(Hook), @hook_hints : HookHints? = nil)
    end

    def add_hook(h : Hook)
      @hooks << h
    end
  end

  # A structure which contains a subset of the fields defined in the evaluation
  # details, representing the result of the provider's flag resolution process
  class ResolutionDetails
    property value : DetailValue
    property error_code : ErrorCode?
    property error_message : String?
    property reason : Reason?
    property variant : String?
    property flag_metadata : FlagMetadata?

    def initialize(@value : DetailValue,
                   *,
                   @variant : String? = nil,
                   @error_code : ErrorCode? = nil,
                   @error_message : String? = nil,
                   @reason : Reason? = nil,
                   @flag_metadata : FlagMetadata? = nil)
    end
  end

  # A structure representing the result of the flag evaluation process,
  # and made available in the detailed flag resolution functions
  class FlagEvaluationDetails < ResolutionDetails
    property flag_key : FlagKey

    def initialize(@flag_key : FlagKey, *,
                   @value : DetailValue,
                   @value_type : Type,
                   @variant : String? = nil,
                   @error_code : ErrorCode? = nil,
                   @error_message : String? = nil,
                   @reason : Reason? = nil,
                   @flag_metadata : FlagMetadata? = nil)
    end

    def initialize(@flag_key : FlagKey, value_type : Type, resolution : ResolutionDetails)
      @value = resolution.value
      @value_type = value_type
      @variant = resolution.variant
      @error_code = resolution.error_code
      @error_message = resolution.error_message
      @reason = resolution.reason
      @flag_metadata = resolution.flag_metadata
    end
  end
end
