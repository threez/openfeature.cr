require "./types"
require "./error"

module OpenFeature
  enum ProviderEvent
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
    # A change was made to the backend flag configuration.
    CONFIGURATION_CHANGED
    # The context associated with the provider has changed,
    # and the provider has reconciled its associated state.
    CONTEXT_CHANGED
  end

  class ProviderEventDetails
    getter flags_changed : Array(String)
    getter message : String?
    getter error_code : ErrorCode?
    getter event_metadata : Metadata

    def initialize(@flags_changed : Array(String),
                   @event_metadata : Metadata,
                   *,
                   @message : String?,
                   @error_code : ErrorCode?)
    end

    def initialize
      @flags_changed = Array(String).new
      @event_metadata = Metadata.new
    end
  end

  class EventDetails < ProviderEventDetails
    getter provider_name : String

    def initialize(@provider_name : String,
                   details : ProviderEventDetails)
      super(details.flags_changed,
        details.event_metadata,
        message: details.message,
        error_code: details.error_code)
    end
  end

  # A function or method which can be associated with a provider event,
  # and runs when that event occurs. It declares an event details parameter.
  alias Handler = Proc(EventDetails, Nil)

  class Client
    getter handlers = Hash(ProviderEvent, Array(Handler)).new

    # add the handler to the client for the given event
    def add_handler(event : ProviderEvent, &handler : Handler)
      handlers = @handlers.fetch(event, Array(Handler).new)
      handlers << handler
      @handlers[event] = handlers
    end

    # remove the handler from the client for the given event
    def remove_handler(event : ProviderEvent, &handler : Handler)
      @handlers[event].delete(handler)
    end
  end

  @@handlers = Hash(ProviderEvent, Array(Handler)).new

  # the list of all globally registered handlers
  def self.handlers
    @@handlers
  end

  # add the handler to the global handler list
  def self.add_handler(event : ProviderEvent, &handler : Handler)
    handlers = @@handlers.fetch(event, Array(Handler).new)
    handlers << handler
    @@handlers[event] = handlers
  end

  # remove the handler from the global handler list
  def self.remove_handler(event : ProviderEvent, &handler : Handler)
    @@handlers[event].delete(handler)
  end
end
