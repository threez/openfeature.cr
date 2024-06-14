# TODO: Write documentation for `Openfeature`
module OpenFeature
  VERSION = "0.1.0"

  class Error < ArgumentError; end

  abstract class Provider
    getter state : ProviderEvents

    def initialize()
      @state = ProviderEvents::NotReady
    end

    abstract def get_boolean_value(flag_key : String,
      default : Bool = true,
      ctx : EvaluationContext? = nil,
      optionse : EvaluationOptions? = nil) : Bool

    abstract def get_string_value(flag_key : String,
      default : String = "",
      ctx : EvaluationContext? = nil,
      optionse : EvaluationOptions? = nil) : String

    abstract def get_number_value(flag_key : String,
      default : Number = 0,
      ctx : EvaluationContext? = nil,
      optionse : EvaluationOptions? = nil) : Number

    abstract def get_object_value(flag_key : String,
      default = nil,
      ctx : EvaluationContext? = nil,
      optionse : EvaluationOptions? = nil)
  end

  class NoopProvider < Provider
    def initialize
      @state = ProviderEvents::Ready
    end

    def get_boolean_value(flag_key : String,
        default : Bool = true,
        ctx : EvaluationContext? = nil,
        optionse : EvaluationOptions? = nil) : Bool
      return default
    end

    def get_string_value(flag_key : String,
      default : String = "",
      ctx : EvaluationContext? = nil,
      optionse : EvaluationOptions? = nil) : String
      return default
    end

    def get_number_value(flag_key : String,
      default : Number = 0,
      ctx : EvaluationContext? = nil,
      optionse : EvaluationOptions? = nil) : Number
      return default
    end

    def get_object_value(flag_key : String,
      default = nil,
      ctx : EvaluationContext? = nil,
      optionse : EvaluationOptions? = nil)
      return default
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
  alias CustomField = Bool | String | Number | Datetime | CustomFields
  alias CustomFields = Hash(String, CustomField)
  alias FlagMetadata = Hash(String, Object)

  class EvaluationContext
    # identifiying the subject of the flag evaluation (e.g. a user)
    property targeting_key : String?

    property custom_fields : CustomFields?
  end

  class EvaluationOptions

  end

  enum ErrorCode
    # ProviderNotReady - the value was resolved before the provider was ready.
    ProviderNotReady
    # FlagNotFound - the flag could not be found.
    FlagNotFound
    # ParseError - an error was encountered parsing data, such as a flag configuration.
    ParseError
    # TypeMismatch - the type of the flag value does not match the expected type.
    TypeMismatch
    # TargetingKeyMissing - the provider requires a targeting key and one was not provided in the evaluation context.
    TargetingKeyMissing
    # InvalidContext - the evaluation context does not meet provider requirements.
    InvalidContext
    # General - the error was for a reason not enumerated above.
    General

    def to_s
      case self
      when ProviderNotReady then "PROVIDER_NOT_READY"
      when FlagNotFound then "FLAG_NOT_FOUND"
      when ParseError then "PARSE_ERROR"
      when TypeMismatch then "TYPE_MISMATCH"
      when TargetingKeyMissing then "TARGETING_KEY_MISSING"
      when InvalidContext then "INVALID_CONTEXT"
      when General then "GENERAL"
      end
    end

    def parse(s : String)
      case s
      when "PROVIDER_NOT_READY" then ProviderNotReady
      when "FLAG_NOT_FOUND" then FlagNotFound
      when "PARSE_ERROR" then ParseError
      when "TYPE_MISMATCH" then TypeMismatch
      when "TARGETING_KEY_MISSING" then TargetingKeyMissing
      when "INVALID_CONTEXT" then InvalidContext
      when "GENERAL" then General
      end
    end
  end

  enum Type
    Bool
    String
    Float
    Int
    Object
  end

  alias DetailValue = Bool | String | Float | Int | CustomFields

  # A structure which contains a subset of the fields defined in the evaluation
  # details, representing the result of the provider's flag resolution process
  class ResolutionDetails
    property value : DetailValue
    property value_type : Type
    property error_code : ErrorCode?
    property error_message : String?
    property reason : String?
    property variant : String?
    property flag_metadata : FlagMetadata?

    def initialize(@value : DetailValue,
      @value_type : Type,
      @variant : String? = nil,
      @error_code : ErrorCode? = nil,
      @error_message : String? = nil,
      @reason : String? = nil,
      @flag_metadata : FlagMetadata? = nil)
    end
  end

  # A structure representing the result of the flag evaluation process,
  # and made available in the detailed flag resolution functions
  class EvaluationDetails < ResolutionDetails
    property flag_key : String

    def initialize(@flag_key : String,
      @value : DetailValue,
      @value_type : Type,
      @variant : String? = nil,
      @error_code : ErrorCode? = nil,
      @error_message : String? = nil,
      @reason : String? = nil,
      @flag_metadata : FlagMetadata? = nil)
    end
  end

  enum Reason
    # The resolved value is static (no dynamic evaluation).
    Static
    # The resolved value fell back to a pre-configured value (no dynamic evaluation occurred or dynamic evaluation yielded no result).
    Default
    # The resolved value was the result of a dynamic evaluation, such as a rule or specific user-targeting.
    TargetingMatch
    # The resolved value was the result of pseudorandom assignment.
    Split
    # The resolved value was retrieved from cache.
    Cached
    # The resolved value was the result of the flag being disabled in the management system.
    Disabled
    # The reason for the resolved value could not be determined.
    Unknown
    # The resolved value is non-authoritative or possibly out of date
    Stale
    # The resolved value was the result of an error.
    Error

    def to_s
      case self
        when Static then "STATIC"
        when Default then "DEFAULT"
        when TargetingMatch then "TARGETING_MATCH"
        when Split then "SPLIT"
        when Cached then "CACHED"
        when Disabled then "DISABLED"
        when Unknown then "UNKNOWN"
        when Stale then "STALE"
        when Error then "ERROR"
      end
    end

    def self.parse(s : String)
      case s
        when "STATIC" then Static
        when "DEFAULT" then Default
        when "TARGETING_MATCH" then TargetingMatch
        when "SPLIT" then Split
        when "CACHED" then Cached
        when "DISABLED" then Disabled
        when "UNKNOWN" then Unknown
        when "STALE" then Stale
        when "ERROR" then Error
      end
    end
  end

  alias HookHints = Hash(String, DetailValue)

  enum ProviderStatus
    # The provider has not been initialized.
    NotReady
    # The provider has been initialized, and is able 
    # to reliably resolve flag values.
    Ready
    # The provider is initialized but is not able to reliably
    # resolve flag values.
    Error
    # The provider's cached state is no longer valid
    # and may not be up-to-date with the source of truth.
    Stale
    # The provider has entered an irrecoverable error state.
    Fatal
    # The provider is reconciling its state with a context change.
    Reconciling
  end
  
  enum ProviderEvents
    NotReady
    # A change was made to the backend flag configuration.
    ConfigurationChanged
    # The provider is ready to perform flag evaluations.
    Ready
    Fatal
    # The provider's cached state is no longer valid and
    # may not be up-to-date with the source of truth.
    Stale
    # The context associated with the provider has
    # changed, and the provider has not yet reconciled 
    # its associated state.
    Reconciling
    # The provider signaled an error.
    Error
    # The context associated with the provider has changed,
    # and the provider has reconciled its associated state.
    ContextChanged
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

  class Client
    property provider : Provider

    def initialize(@provider : Provider)
      @handlers = Hash(ProviderEvents, Array(Handler)).new
    end

    def get_boolean_value(flag_key : String,
        default : Bool = true,
        ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : Bool
      return @provider.get_boolean_value(flag_key, default, ctx, options)
    end

    def get_string_value(flag_key : String,
        default : String = "",
        ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : String
      return @provider.get_string_value(flag_key, default, ctx, options)
    end

    def get_number_value(flag_key : String,
        default : Number = 0,
        ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : Number
      return @provider.get_number_value(flag_key, default, ctx, options)
    end

    def get_object_value(flag_key : String,
        default = nil,
        ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil)
      return @provider.get_object_value(flag_key, default, ctx, options)
    end

    def add_handler(event : ProviderEvents, &handler : Handler)
      @handlers[event] << handler
    end
  end

  DEFAULT_PROVIDER_DOMAIN = ""

  @@providers = {} of String => Provider

  def self.set_provider(provider : Provider, domain : String = DEFAULT_PROVIDER_DOMAIN)
    @@providers[domain] = provider
  end

  def self.get_provider(domain : String = DEFAULT_PROVIDER_DOMAIN) : Provider
    @@providers.fetch(domain, @@providers[DEFAULT_PROVIDER_DOMAIN])
  end

  def self.get_client(domain : String = DEFAULT_PROVIDER_DOMAIN) : Client
    provider = get_provider(domain)
    return Client.new(provider)
  end
end
