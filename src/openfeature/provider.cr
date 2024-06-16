require "./error"
require "./event"
require "./evaluation"

module OpenFeature
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

  class ProviderEventDetails
    property flags_changed : Array(String)
    property message : String?
    property error_code : ErrorCode?
    property event_metadata : EventMetadata = {} of String => DetailValue

    def initialize(@flags_changed : Array(String))
    end
  end

  class ProviderMetadata
    property name : String

    def initialize(@name : String)
    end
  end

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
      @evaluation_context = ectx || EvaluationContext.new
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
end
