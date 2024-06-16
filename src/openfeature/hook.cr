require "./types"
require "./evaluation"
require "./provider"
require "./client"

module OpenFeature
  @@hooks = Array(Hook).new

  def self.add_hook(&h : Hook)
    @@hooks << h
  end

  def self.hooks
    @@hooks
  end

  class HookContext
    getter flag_key : String
    getter flag_value_type : Type
    getter default_value : DetailValue
    getter evaluation_context : EvaluationContext
    getter provider_metadata : ProviderMetadata
    getter client_metadata : ClientMetadata

    def initialize(@flag_key : String,
                   @flag_value_type : Type,
                   @default_value : DetailValue,
                   @evaluation_context : EvaluationContext,
                   @provider_metadata : ProviderMetadata,
                   @client_metadata : ClientMetadata)
    end
  end

  alias HookHints = Hash(String, DetailValue)

  # Hooks are a mechanism whereby application developers can add arbitrary behavior to flag evaluation.
  # They operate similarly to middleware in many web frameworks.
  #
  # Hooks add their logic at any of four specific stages of flag evaluation:
  #
  # `before`, immediately before flag evaluation
  # `after`, immediately after successful flag evaluation
  # `error`, immediately after an unsuccessful during flag evaluation
  # `finally` unconditionally after flag evaluation
  #
  # ![](https://openfeature.dev/assets/images/life-cycle-7fb3185fab0ddd53634548321c8147c0.png)
  #
  # Hooks can be configured to run globally (impacting all flag evaluations), per client, or per
  # flag evaluation invocation. Some example use-cases for hook include adding additional data to
  # the evaluation context, performing validation on the received flag value, providing data to telemetric
  # tools, and logging errors.
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
end
