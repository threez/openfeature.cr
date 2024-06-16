require "../hook"

module OpenFeature
  alias ProcStageHook = Proc(HookContext, HookHints, EvaluationContext?)

  def self.add_proc_hook(*,
                         before : ProcStageHook? = nil,
                         after : ProcStageHook? = nil,
                         error : ProcStageHook? = nil,
                         finally : ProcStageHook? = nil)
    @@hooks << Hooks::ProcHook.new(before: before, after: after, error: error, finally: finally)
  end

  module Hooks
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
end
