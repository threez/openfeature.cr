# TODO: Write documentation for `Openfeature`
module OpenFeature
  VERSION = "0.1.0"

  class Error < ArgumentError; end

  class ProviderMetadata
    property name : String

    def initialize(@name : String)
    end
  end

  class ProviderError < Error
    property code : ErrorCode

    def initialize(@code : ErrorCode, msg : String)
      super(msg)
    end
  end

  abstract class Hook
    # immediately before flag evaluation
    abstract def before(ctx : HookContext, hints : HookHints) : EvaluationContext?
    
    # immediately after successful flag evaluation
    abstract def after(ctx : HookContext, hints : HookHints)

    # immediately after an unsuccessful during flag evaluation
    abstract def error(ctx : HookContext, hints : HookHints)

    # unconditionally after flag evaluation
    abstract def finally(ctx : HookContext, hints : HookHints) 
  end

  alias ProcStageHook = Proc(HookContext, HookHints, EvaluationContext?)

  class ProcHook < Hook
    def initialize(*, @before : ProcStageHook? = nil,
                   @after : ProcStageHook? = nil,
                   @error : ProcStageHook? = nil,
                   @finally : ProcStageHook? = nil)
    end
    
    {% for name in %w(before after error finally) %}
    def {{ name.id }}(ctx : HookContext, hints : HookHints) : EvaluationContext?
      unless @{{ name.id }}.nil?
        @{{ name.id }}.not_nil!.call(ctx, hints)
      end
    end
    {% end %}
  end

  # The provider API defines interfaces that Provider Authors can use to abstract a
  # particular flag management system, thus enabling the use of the evaluation API
  # by Application Authors.
  # 
  # Providers are the "translator" between the flag evaluation calls made in application
  # code, and the flag management system that stores flags and in some cases evaluates
  # flags. At a minimum, providers should implement some basic evaluation methods which
  # return flag values of the expected type. In addition, providers may transform the
  # evaluation context appropriately in order to be used in dynamic evaluation of their
  # associated flag management system, provide insight into why evaluation proceeded
  # the way it did, and expose configuration options for their associated flag management
  # system. Hypothetical provider implementations might wrap a vendor SDK, embed an REST
  # client, or read flags from a local file.
  abstract class Provider
    getter state : ProviderEvents
    getter metadata : ProviderMetadata
    getter evaluation_context : EvaluationContext

    def initialize(name : String, ectx : EvaluationContext? = nil)
      @state = ProviderEvents::NOT_READY
      @metadata = ProviderMetadata.new(name)
      @hooks = Hash(String, Array(Hook)).new
      @evaluation_context = ectx || EvaluationContext.new()
    end

    abstract def resolve_boolean_value(flag_key : String,
      default : Bool = true,
      ctx : EvaluationContext? = nil) : ResolutionDetails(Bool)

    abstract def resolve_string_value(flag_key : String,
      default : String = "",
      ctx : EvaluationContext? = nil) : ResolutionDetails(String)

    abstract def resolve_number_value(flag_key : String,
      default : Number = 0,
      ctx : EvaluationContext? = nil) : ResolutionDetails(Number)

    abstract def resolve_object_value(flag_key : String,
      default = nil,
      ctx : EvaluationContext? = nil) : ResolutionDetails
  end

  abstract class AutoDisposable
    # called to gracefully shutdown the provider, if a provider requires
    # initialization, once it's shut down, it must transition to its 
    # initial NOT_READY state. Some providers may allow reinitialization 
    # from this state. Providers not requiring initialization are assumed 
    # to be ready at all times.
    abstract def dispose
  end

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

  alias Int = Int8 | Int16 | Int32 | Int64
  alias Float = Float32 | Float64
  
  # A numeric value of unspecified type or size. Implementation 
  # languages may further differentiate between integers, floating
  # point numbers, and other specific numeric types and provide
  # functionality as idioms dictate.
  alias Number = Int | Float

  # A language primitive for representing a date and time, optionally
  # including timezone information. If no timezone is specified, the date
  # and time will be treated as UTC.
  alias Datetime = Time
  alias CustomField = Bool | String | Number | Datetime
  alias CustomFields = Hash(String, CustomField)
  alias FlagMetadata = Hash(String, Object)

  enum Type
    # A logical true or false, as represented idiomatically in
    # the implementation languages.
    Boolean
    # A UTF-8 encoded string.
    String
    # A numeric value of unspecified type or size. Implementation
    # languages may further differentiate between integers, floating
    # point numbers, and other specific numeric types and provide
    # functionality as idioms dictate.
    Number
    # Structured data, presented however is idiomatic in the
    # implementation language, such as JSON or YAML.
    Structure
    # A language primitive for representing a date and time, optionally
    # including timezone information. If no timezone is specified, the
    # date and time will be treated as UTC.
    Datetime
  end

  class HookContext
    getter flag_key : String
    getter flag_value_type : Type
    # TODO: getter default_value
    getter evaluation_context : EvaluationContext
    getter provider_metadata : ProviderMetadata
    getter client_metadata : ClientMetadata

    def initialize(@flag_key : String,
      @flag_value_type : Type,
      # TODO: @default_value,
      @evaluation_context : EvaluationContext,
      @provider_metadata : ProviderMetadata,
      @client_metadata : ClientMetadata)
    end
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
    property targeting_key : String?

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

  class EvaluationOptions
    property hooks : Array(Hook)?
    property hook_hints : HookHints?

    def initialize(@hooks : Array(Hook)?, @hook_hints : HookHints?)
    end
  end

  enum ErrorCode
    # The value was resolved before the provider was ready.
    PROVIDER_NOT_READY
    # The flag could not be found.
    FLAG_NOT_FOUND
    # An error was encountered parsing data, such as a flag configuration.
    PARSE_ERROR
    # The type of the flag value does not match the expected type.
    TYPE_MISMATCH
    # The provider requires a targeting key and one was not provided in the evaluation context.
    TARGETING_KEY_MISSING
    # The evaluation context does not meet provider requirements.
    INVALID_CONTEXT
    # The error was for a reason not enumerated above.
    GENERAL
  end

  alias DetailValue = Bool | String | Float | Int | CustomFields

  # A structure which contains a subset of the fields defined in the evaluation
  # details, representing the result of the provider's flag resolution process
  class ResolutionDetails(T)
    property value : T
    property error_code : ErrorCode?
    property error_message : String?
    property reason : Reason?
    property variant : String?
    property flag_metadata : FlagMetadata?

    def initialize(@value : T, *,
      @variant : String? = nil,
      @error_code : ErrorCode? = nil,
      @error_message : String? = nil,
      @reason : Reason? = nil,
      @flag_metadata : FlagMetadata? = nil)
    end
  end

  # A structure representing the result of the flag evaluation process,
  # and made available in the detailed flag resolution functions
  class FlagEvaluationDetails(T) < ResolutionDetails(T)
    property flag_key : String

    def initialize(@flag_key : String, *,
      @value : DetailValue,
      @value_type : Type,
      @variant : String? = nil,
      @error_code : ErrorCode? = nil,
      @error_message : String? = nil,
      @reason : Reason? = nil,
      @flag_metadata : FlagMetadata? = nil)
    end

    def initialize(@flag_key : String, value_type : Type, resolution : ResolutionDetails(T))
      @value = resolution.value
      @value_type = value_type
      @variant = resolution.variant
      @error_code = resolution.error_code
      @error_message = resolution.error_message
      @reason = resolution.reason
      @flag_metadata = resolution.flag_metadata
    end
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

  alias HookHints = Hash(String, DetailValue)

  enum ProviderStatus
    # The provider has not been initialized.
    NOT_READY
    # The provider has been initialized, and is able 
    # to reliably resolve flag values.
    READY
    # The provider is initialized but is not able to reliably
    # resolve flag values.
    ERROR
    # The provider's cached state is no longer valid
    # and may not be up-to-date with the source of truth.
    STALE
    # The provider has entered an irrecoverable error state.
    FATAL
    # The provider is reconciling its state with a context change.
    RECONCILING
  end
  
  enum ProviderEvents
    NOT_READY
    # A change was made to the backend flag configuration.
    CONFIGURATION_CHANGED
    # The provider is ready to perform flag evaluations.
    READY
    FATAL
    # The provider's cached state is no longer valid and
    # may not be up-to-date with the source of truth.
    STALE
    # The context associated with the provider has
    # changed, and the provider has not yet reconciled 
    # its associated state.
    RECONCILING
    # The provider signaled an error.
    ERROR
    # The context associated with the provider has changed,
    # and the provider has reconciled its associated state.
    CONTEXT_CHANGED
  end
  
  alias EventMetadata = Hash(String, DetailValue)

  class ProviderEventDetails
    property flags_changed : Array(String)
    property message : String?
    property error_code : ErrorCode?
    property event_metadata : EventMetadata = {} of String => DetailValue

    def initialize(@flags_changed : Array(String))
      
    end
  end

  alias Handler = Proc(ProviderEvents)

  class ClientMetadata

  end

  class Client
    getter provider : Provider
    getter evaluation_context : EvaluationContext
    getter metadata : ClientMetadata

    def initialize(@provider : Provider, ectx : EvaluationContext? = nil)
      @handlers = Hash(ProviderEvents, Array(Handler)).new
      @evaluation_context = ectx || EvaluationContext.new()
      @metadata = ClientMetadata.new
    end

    ## Value

    def boolean_value(flag_key : String,
        default : Bool = true,
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : Bool
      return boolean_details(flag_key, default, context: ctx, options: options).value
    end

    def string_value(flag_key : String,
        default : String = "",
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : String
      return string_details(flag_key, default, context: ctx, options: options).value
    end

    def number_value(flag_key : String,
        default : Number = 0,
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : Number
      return number_details(flag_key, default, context: ctx, options: options).value
    end

    def object_value(flag_key : String,
        default = nil,
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil)
      return object_details(flag_key, default, context: ctx, options: options).value
    end

    {% for name in %w(before after error finally) %}
      private def call_{{ name.id }}_hooks(flag_key : String,
                            flag_type : Type,
                            default,
                            ctx : EvaluationContext? = nil,
                            options : EvaluationOptions? = nil)
        hooks = OpenFeature.hooks
        hints = HookHints.new
        unless options.nil?
          hooks = hooks + options.hooks
          hints ||= options.hints
        end

        merged_ctx = EvaluationContext.merged(client: @evaluation_context, invocation: ctx)
        hooks.each do |hook|
          hook_ctx = HookContext.new(flag_key, Type::Boolean, merged_ctx, provider.metadata, @metadata)
          if new_ctx = hook.{{ name.id }}(hook_ctx, hints)
            merged_ctx = merged_ctx.merge(new_ctx)
          end
        end
        merged_ctx
      end
    {% end %}

    ## Details
    
    def boolean_details(flag_key : String,
        default : Bool = true,
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : FlagEvaluationDetails(Bool)
      merged_ctx = call_before_hooks(flag_key, Type::Boolean, default, ctx, options)
      details = @provider.resolve_boolean_value(flag_key, default, merged_ctx)
      return FlagEvaluationDetails(Bool).new(flag_key, Type::Boolean, details)
    end

    def string_details(flag_key : String,
        default : String = "",
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : FlagEvaluationDetails(String)
      details = @provider.resolve_string_value(flag_key, default, ctx)
      return FlagEvaluationDetails(String).new(flag_key, Type::String, details)
    end

    def number_details(flag_key : String,
        default : Number = 0,
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : FlagEvaluationDetails(Number)
      details = @provider.resolve_number_value(flag_key, default, ctx)
      return FlagEvaluationDetails(Number).new(flag_key, Type::Number, details)
    end

    def object_details(flag_key : String,
        default = nil,
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil)
      details = @provider.resolve_object_value(flag_key, default, ctx)
      return FlagEvaluationDetails.new(flag_key, Type::Structure, details)
    end

    ## Handler

    def add_handler(event : ProviderEvents, &handler : Handler)
      @handlers[event] << handler
    end
  end

  @@context : EvaluationContext?

  def self.global_context=(context ctx : EvaluationContext)
    @@context = ctx
  end

  def self.global_context : EvaluationContext?
    @@context
  end

  @@hooks = Array(Hook).new

  def self.add_hook(&h : Hook)
    @@hooks << h
  end

  def self.add_proc_hook(*,
                         before : ProcStageHook? = nil,
                         after : ProcStageHook? = nil,
                         error : ProcStageHook? = nil,
                         finally : ProcStageHook? = nil)
    @@hooks << ProcHook.new(before: before, after: after, error: error, finally: finally)
  end

  def self.hooks
    @@hooks
  end

  DEFAULT_PROVIDER_DOMAIN = ""

  @@providers = {} of String => Provider
  
  def self.provider=(provider : Provider)
    @@providers[DEFAULT_PROVIDER_DOMAIN] = provider
  end

  def self.set_provider(provider : Provider, domain : String = DEFAULT_PROVIDER_DOMAIN)
    @@providers[domain] = provider
  end

  def self.provider(domain : String = DEFAULT_PROVIDER_DOMAIN) : Provider
    @@providers.fetch(domain, @@providers[DEFAULT_PROVIDER_DOMAIN])
  end

  def self.client(domain : String = DEFAULT_PROVIDER_DOMAIN, *, 
                  context ectx : EvaluationContext? = nil) : Client
    return Client.new(provider(domain), ectx)
  end

  def self.transaction_context=(ctx : EvaluationContext)
    Fiber.current.openfeature_transaction_context = ctx
  end

  # retuerns the current transaction context or a new context without content
  def self.transaction_context : EvaluationContext?
    Fiber.current.openfeature_transaction_context
  end
end

class Fiber
  # Transaction context is a container for transaction-specific evaluation context
  # (e.g. user id, user agent, IP). Transaction context can be set where specific data
  # is available (e.g. an auth service or request handler) 
  property openfeature_transaction_context : OpenFeature::EvaluationContext?
end
