
require "./types"

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

  alias EventMetadata = Hash(String, DetailValue)

  alias Handler = Proc(ProviderEvents)
end
