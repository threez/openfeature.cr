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
    getter flag_key : FlagKey
    getter flag_value_type : Type
    getter default_value : DetailValue
    getter evaluation_context : EvaluationContext
    getter provider_metadata : ProviderMetadata
    getter client_metadata : ClientMetadata

    def initialize(@flag_key : FlagKey,
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
    abstract def after(ctx : HookContext, hints : HookHints, flag_details : FlagEvaluationDetails)

    # immediately after an unsuccessful during flag evaluation
    abstract def error(ctx : HookContext, hints : HookHints, ex : Exception)

    # unconditionally after flag evaluation
    abstract def finally(ctx : HookContext, hints : HookHints)
  end

  class Client
    getter hooks = Array(Hook).new

    def add_hook(h : Hook)
      @hooks << h
    end

    private def hooks_hints(options : EvaluationOptions? = nil) : EvaluationOptions
      hooks = OpenFeature.hooks + @hooks
      hints = HookHints.new
      unless options.nil?
        hooks = hooks + options.hooks
        hints = options.hook_hints
      end
      EvaluationOptions.new(hooks, hints)
    end

    def with_hooks(flag_key : FlagKey,
                   flag_type : Type,
                   default : DetailValue,
                   ctx : EvaluationContext? = nil,
                   options : EvaluationOptions? = nil,
                   &)
      computed_options = hooks_hints(options)
      merged_ctx = EvaluationContext.merged(client: @evaluation_context, invocation: ctx)
      hook_ctx = uninitialized HookContext
      computed_options.hooks.each do |hook|
        hook_ctx = HookContext.new(flag_key, Type::Boolean, default, merged_ctx, provider.metadata, @metadata)
        if new_ctx = hook.before(hook_ctx, computed_options.hook_hints)
          merged_ctx = merged_ctx.merge(new_ctx)
        end
      end

      begin
        result = yield(merged_ctx)
        computed_options.hooks.each do |hook|
          hook.after(hook_ctx, computed_options.hook_hints, result)
        end
        result
      rescue exception
        computed_options.hooks.each do |hook|
          hook.error(hook_ctx, computed_options.hook_hints, exception)
        end
        raise exception
      ensure
        computed_options.hooks.each do |hook|
          hook.finally(hook_ctx, computed_options.hook_hints)
        end
      end
    end
  end
end
