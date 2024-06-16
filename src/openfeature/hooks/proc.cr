require "../hook"

module OpenFeature
  # A single hook stage, either before, error, after or finally
  alias ProcStageHook = Proc(HookContext, HookHints, EvaluationContext?)

  # Add proc based hook to global hooks
  def self.add_proc_hook(*,
                         before : ProcStageHook? = nil,
                         after : ProcStageHook? = nil,
                         error : ProcStageHook? = nil,
                         finally : ProcStageHook? = nil)
    @@hooks << Hooks::ProcHook.new(before: before, after: after, error: error, finally: finally)
  end

  class Client
    # Add proc based hook to client hooks
    def add_proc_hook(*,
                      before : ProcStageHook? = nil,
                      after : ProcStageHook? = nil,
                      error : ProcStageHook? = nil,
                      finally : ProcStageHook? = nil)
      add_hook Hooks::ProcHook.new(before: before, after: after, error: error, finally: finally)
    end
  end

  class EvaluationOptions
    # Add proc based hook to invocation hooks
    def add_proc_hook(*,
                      before : ProcStageHook? = nil,
                      after : ProcStageHook? = nil,
                      error : ProcStageHook? = nil,
                      finally : ProcStageHook? = nil)
      add_hook Hooks::ProcHook.new(before: before, after: after, error: error, finally: finally)
    end
  end

  module Hooks
    # Implements a Hook that will call the provided hook `ProcStageHook` for the
    # given methods.
    class ProcHook < Hook
      def initialize(*, @before : ProcStageHook? = nil,
                     @after : ProcStageHook? = nil,
                     @error : ProcStageHook? = nil,
                     @finally : ProcStageHook? = nil)
      end

      {% for name in %w(before after error finally) %}
      # calls the {{ name.id }} hook proc
      def {{ name.id }}(ctx : HookContext, hints : HookHints) : EvaluationContext?
        unless @{{ name.id }}.nil?
          @{{ name.id }}.not_nil!.call(ctx, hints)
        end
      end
      {% end %}
    end
  end
end
