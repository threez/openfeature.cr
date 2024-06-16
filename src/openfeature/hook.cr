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
    getter default_value : Value
    getter evaluation_context : EvaluationContext
    getter provider_metadata : Metadata
    getter client_metadata : Metadata

    def initialize(@flag_key : FlagKey,
                   @flag_value_type : Type,
                   @default_value : Value,
                   @evaluation_context : EvaluationContext,
                   @provider_metadata : Metadata,
                   @client_metadata : Metadata)
    end
  end

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
    abstract def before(ctx : HookContext, hints : Metadata) : EvaluationContext?

    # immediately after successful flag evaluation
    abstract def after(ctx : HookContext, hints : Metadata, flag_details : FlagEvaluationDetails)

    # immediately after an unsuccessful during flag evaluation
    abstract def error(ctx : HookContext, hints : Metadata, ex : Exception)

    # unconditionally after flag evaluation
    abstract def finally(ctx : HookContext, hints : Metadata)
  end

  class Client
    getter hooks = Array(Hook).new

    # add the passed hook
    def add_hook(h : Hook)
      @hooks << h
    end

    # remove the passed hook
    def remove_hook(h : Hook)
      @hooks.delete(h)
    end

    # creates evaluation options based on the global and
    # client settings using the passed invocation hints
    private def hooks_hints(options : EvaluationOptions? = nil) : EvaluationOptions
      hooks = OpenFeature.hooks + @hooks
      hints = Metadata.new
      unless options.nil?
        hooks = hooks + options.hooks
        hints = options.hook_hints
      end
      EvaluationOptions.new(hooks, hints)
    end

    # executes the hooks around a provider interaction
    private def with_hooks(flag_key : FlagKey,
                           flag_type : Type,
                           default : Value,
                           ctx : EvaluationContext? = nil,
                           options : EvaluationOptions? = nil,
                           &)
      computed_options = hooks_hints(options)
      merged_ctx = EvaluationContext.merged(client: @evaluation_context, invocation: ctx)
      hook_ctx = uninitialized HookContext
      computed_options.hooks.each do |hook|
        hook_ctx = HookContext.new(flag_key, flag_type, default, merged_ctx, provider.metadata, @metadata)
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
