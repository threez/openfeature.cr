require "./types"
require "./error"

module OpenFeature
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

  alias DetailValue = Bool | String | Float | Int | CustomFields

  # A structure supporting the addition of arbitrary event data.
  # It supports definition of arbitrary properties, with keys of
  # type string, and values of type boolean, string, or number.
  alias EventMetadata = Hash(String, DetailValue)

  # A function or method which can be associated with a provider event,
  # and runs when that event occurs. It declares an event details parameter.
  alias Handler = Proc(EventDetails)

  class ProviderEventDetails
    getter flags_changed : Array(String)
    getter message : String?
    getter error_code : ErrorCode?
    getter event_metadata : EventMetadata

    def initialize(@provider_name : String,
                   @flags_changed : Array(String),
                   @event_metadata : EventMetadata,
                   *,
                   @message : String?,
                   @error_code : ErrorCode?)
    end
  end

  class EventDetails < ProviderEventDetails
    getter provider_name : String

    def initialize(@provider_name : String,
                   @flags_changed : Array(String),
                   @event_metadata : EventMetadata,
                   *,
                   @message : String?,
                   @error_code : ErrorCode?)
    end
  end

  class Client
    @handlers = Hash(ProviderEvents, Array(Handler)).new

    def add_handler(event : ProviderEvents, &handler : Handler)
      @handlers[event] << handler
    end

    def remove_handler(event : ProviderEvents, &handler : Handler)
      @handlers[event].delete(handler)
    end
  end

  @@handlers = Hash(ProviderEvents, Array(Handler)).new

  def self.add_handler(event : ProviderEvents, &handler : Handler)
    @@handlers[event] << handler
  end

  def self.remove_handler(event : ProviderEvents, &handler : Handler)
    @@handlers[event].delete(handler)
  end
end
