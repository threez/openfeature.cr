require "../hook"

module OpenFeature
  alias BeforeStageHook = Proc(HookContext, HookHints, EvaluationContext?)
  alias AfterStageHook = Proc(HookContext, HookHints, FlagEvaluationDetails, Nil)
  alias ErrorStageHook = Proc(HookContext, HookHints, Exception, Nil)
  alias FinallyStageHook = Proc(HookContext, HookHints, Nil)

  # Add proc based hook to global hooks
  def self.add_proc_hook(*,
                         before : BeforeStageHook? = nil,
                         after : AfterStageHook? = nil,
                         error : ErrorStageHook? = nil,
                         finally : FinallyStageHook? = nil)
    @@hooks << Hooks::ProcHook.new(before: before, after: after, error: error, finally: finally)
  end

  class Client
    # Add proc based hook to client hooks
    def add_proc_hook(*,
                      before : BeforeStageHook? = nil,
                      after : AfterStageHook? = nil,
                      error : ErrorStageHook? = nil,
                      finally : FinallyStageHook? = nil)
      add_hook Hooks::ProcHook.new(before: before, after: after, error: error, finally: finally)
    end
  end

  class EvaluationOptions
    # Add proc based hook to invocation hooks
    def add_proc_hook(*,
                      before : BeforeStageHook? = nil,
                      after : AfterStageHook? = nil,
                      error : ErrorStageHook? = nil,
                      finally : FinallyStageHook? = nil)
      add_hook Hooks::ProcHook.new(before: before, after: after, error: error, finally: finally)
    end
  end

  module Hooks
    # Implements a Hook that will call the provided hook for the given methods.
    class ProcHook < Hook
      def initialize(*,
                     @before : BeforeStageHook? = nil,
                     @after : AfterStageHook? = nil,
                     @error : ErrorStageHook? = nil,
                     @finally : FinallyStageHook? = nil)
      end

      # calls the before hook proc
      def before(ctx : HookContext, hints : HookHints) : EvaluationContext?
        if proc = @before
          proc.call(ctx, hints)
        end
      end

      # calls the after hook proc
      def after(ctx : HookContext, hints : HookHints, flag_details : FlagEvaluationDetails)
        if proc = @after
          proc.call(ctx, hints, flag_details)
        end
      end

      # calls the error hook proc
      def error(ctx : HookContext, hints : HookHints, ex : Exception)
        if proc = @error
          proc.call(ctx, hints, ex)
        end
      end

      # calls the finally hook proc
      def finally(ctx : HookContext, hints : HookHints)
        if proc = @finally
          proc.call(ctx, hints)
        end
      end
    end
  end
end
