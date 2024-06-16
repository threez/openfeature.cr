require "./types"
require "./evaluation"
require "./provider"
require "./client"

module OpenFeature
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

  alias HookHints = Hash(String, DetailValue)

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
end
