require "./error"
require "./event"
require "./evaluation"

module OpenFeature
  DEFAULT_PROVIDER_DOMAIN = ""

  @@providers = Hash(Domain, Provider).new

  def self.provider=(provider : Provider)
    set_provider(provider, domain: DEFAULT_PROVIDER_DOMAIN)
  end

  def self.set_provider(provider : Provider, domain : Domain = DEFAULT_PROVIDER_DOMAIN)
    @@providers[domain] = provider
  end

  def self.provider(domain : Domain = DEFAULT_PROVIDER_DOMAIN) : Provider
    @@providers.fetch(domain, @@providers[DEFAULT_PROVIDER_DOMAIN])
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
    getter name : String
    getter state : ProviderEvent
    getter metadata : Metadata
    getter evaluation_context : EvaluationContext

    def initialize(@name : String,
                   *,
                   evaluation_context ectx : EvaluationContext? = nil,
                   metadata md : Metadata? = nil,
                   @hooks = Hash(String, Array(Hook)).new)
      @state = ProviderEvent::NOT_READY
      @metadata = md || Metadata.new
      @metadata["name"] = name
      @evaluation_context = ectx || EvaluationContext.new
      @clients = Array(Client).new
    end

    # adds the passed client to the list of clients
    def add_client(client : Client)
      @clients << client
    end

    # remove the clinet from the provider
    def remove_client(client : Client)
      @client.delete(client)
    end

    # sets the state and emits an event for it
    private def set_state(event : ProviderEvent)
      @state = event
      emit_event(@state, ProviderEventDetails.new)
    end

    # emits event to global and client providers registered
    private def emit_event(event : ProviderEvent, details : ProviderEventDetails)
      if handlers = OpenFeature.handlers.fetch(event, Array(Handler).new)
        handlers.each do |handler|
          handler.call(EventDetails.new(@name, details))
        end
      end

      @clients.each do |client|
        if handlers = client.handlers.fetch(event, Array(Handler).new)
          handlers.each do |handler|
            handler.call(EventDetails.new(@name, details))
          end
        end
      end
    end

    abstract def resolve_boolean_value(flag_key : FlagKey,
                                       default : Bool = true,
                                       ctx : EvaluationContext? = nil) : ResolutionDetails

    abstract def resolve_string_value(flag_key : FlagKey,
                                      default : String = "",
                                      ctx : EvaluationContext? = nil) : ResolutionDetails

    abstract def resolve_number_value(flag_key : FlagKey,
                                      default : Number = 0,
                                      ctx : EvaluationContext? = nil) : ResolutionDetails

    abstract def resolve_object_value(flag_key : FlagKey,
                                      default : Structure,
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
