require "./types"
require "./provider"

module OpenFeature
  def self.client(domain : String = DEFAULT_PROVIDER_DOMAIN, *,
                  context ectx : EvaluationContext? = nil) : Client
    return Client.new(provider(domain), ectx)
  end

  class ClientMetadata

  end

  class Client
    getter provider : Provider
    getter evaluation_context : EvaluationContext
    getter metadata : ClientMetadata

    def initialize(@provider : Provider, ectx : EvaluationContext? = nil)
      @handlers = Hash(ProviderEvents, Array(Handler)).new
      @evaluation_context = ectx || EvaluationContext.new()
      @metadata = ClientMetadata.new
    end

    ## Value

    def boolean_value(flag_key : String,
        default : Bool = true,
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : Bool
      return boolean_details(flag_key, default, context: ctx, options: options).value
    end

    def string_value(flag_key : String,
        default : String = "",
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : String
      return string_details(flag_key, default, context: ctx, options: options).value
    end

    def number_value(flag_key : String,
        default : Number = 0,
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : Number
      return number_details(flag_key, default, context: ctx, options: options).value
    end

    def object_value(flag_key : String,
        default = nil,
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil)
      return object_details(flag_key, default, context: ctx, options: options).value
    end

    {% for name in %w(before after error finally) %}
      private def call_{{ name.id }}_hooks(flag_key : String,
                            flag_type : Type,
                            default,
                            ctx : EvaluationContext? = nil,
                            options : EvaluationOptions? = nil)
        hooks = OpenFeature.hooks
        hints = HookHints.new
        unless options.nil?
          hooks = hooks + options.hooks
          hints ||= options.hints
        end

        merged_ctx = EvaluationContext.merged(client: @evaluation_context, invocation: ctx)
        hooks.each do |hook|
          hook_ctx = HookContext.new(flag_key, Type::Boolean, merged_ctx, provider.metadata, @metadata)
          if new_ctx = hook.{{ name.id }}(hook_ctx, hints)
            merged_ctx = merged_ctx.merge(new_ctx)
          end
        end
        merged_ctx
      end
    {% end %}

    ## Details

    def boolean_details(flag_key : String,
        default : Bool = true,
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : FlagEvaluationDetails(Bool)
      merged_ctx = call_before_hooks(flag_key, Type::Boolean, default, ctx, options)
      details = @provider.resolve_boolean_value(flag_key, default, merged_ctx)
      return FlagEvaluationDetails(Bool).new(flag_key, Type::Boolean, details)
    end

    def string_details(flag_key : String,
        default : String = "",
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : FlagEvaluationDetails(String)
      details = @provider.resolve_string_value(flag_key, default, ctx)
      return FlagEvaluationDetails(String).new(flag_key, Type::String, details)
    end

    def number_details(flag_key : String,
        default : Number = 0,
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil) : FlagEvaluationDetails(Number)
      details = @provider.resolve_number_value(flag_key, default, ctx)
      return FlagEvaluationDetails(Number).new(flag_key, Type::Number, details)
    end

    def object_details(flag_key : String,
        default = nil,
        *,
        context ctx : EvaluationContext? = nil,
        options : EvaluationOptions? = nil)
      details = @provider.resolve_object_value(flag_key, default, ctx)
      return FlagEvaluationDetails.new(flag_key, Type::Structure, details)
    end

    ## Handler

    def add_handler(event : ProviderEvents, &handler : Handler)
      @handlers[event] << handler
    end
  end
end
