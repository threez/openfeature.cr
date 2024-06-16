require "./types"
require "./provider"

module OpenFeature
  def self.client(domain : Domain = DEFAULT_PROVIDER_DOMAIN, *,
                  context ectx : EvaluationContext? = nil) : Client
    Client.new(provider(domain), ectx)
  end

  class ClientMetadata
  end

  # A lightweight abstraction that provides functions to evaluate feature flags.
  # A client is associated with a single provider, which it uses to perform evaluations.
  class Client
    getter provider : Provider
    getter evaluation_context : EvaluationContext
    getter metadata : ClientMetadata

    def initialize(@provider : Provider, ectx : EvaluationContext? = nil)
      @evaluation_context = ectx || EvaluationContext.new
      @metadata = ClientMetadata.new
    end

    # # Value

    def boolean_value(flag_key : FlagKey,
                      default : Bool = true,
                      *,
                      context ctx : EvaluationContext? = nil,
                      options : EvaluationOptions? = nil) : Bool
      boolean_details(flag_key, default, context: ctx, options: options).value.as(Bool)
    end

    def string_value(flag_key : FlagKey,
                     default : String = "",
                     *,
                     context ctx : EvaluationContext? = nil,
                     options : EvaluationOptions? = nil) : String
      string_details(flag_key, default, context: ctx, options: options).value.as(String)
    end

    def number_value(flag_key : FlagKey,
                     default : Number = 0,
                     *,
                     context ctx : EvaluationContext? = nil,
                     options : EvaluationOptions? = nil) : Number
      number_details(flag_key, default, context: ctx, options: options).value.as(Number)
    end

    def object_value(flag_key : FlagKey,
                     default = CustomFields,
                     *,
                     context ctx : EvaluationContext? = nil,
                     options : EvaluationOptions? = nil) : CustomFields
      object_details(flag_key, default, context: ctx, options: options).value.as(CustomFields)
    end

    # # Details

    def boolean_details(flag_key : FlagKey,
                        default : Bool = true,
                        *,
                        context ctx : EvaluationContext? = nil,
                        options : EvaluationOptions? = nil) : FlagEvaluationDetails
      with_hooks(flag_key, Type::Boolean, default, ctx, options) do |merged_ctx|
        details = @provider.resolve_boolean_value(flag_key, default, merged_ctx)
        FlagEvaluationDetails.new(flag_key, Type::Boolean, details)
      end
    end

    def string_details(flag_key : FlagKey,
                       default : String = "",
                       *,
                       context ctx : EvaluationContext? = nil,
                       options : EvaluationOptions? = nil) : FlagEvaluationDetails
      with_hooks(flag_key, Type::String, default, ctx, options) do |merged_ctx|
        details = @provider.resolve_string_value(flag_key, default, merged_ctx)
        FlagEvaluationDetails.new(flag_key, Type::String, details)
      end
    end

    def number_details(flag_key : FlagKey,
                       default : Number = 0,
                       *,
                       context ctx : EvaluationContext? = nil,
                       options : EvaluationOptions? = nil) : FlagEvaluationDetails
      with_hooks(flag_key, Type::String, default, ctx, options) do |merged_ctx|
        details = @provider.resolve_number_value(flag_key, default, merged_ctx)
        FlagEvaluationDetails.new(flag_key, Type::Number, details)
      end
    end

    def object_details(flag_key : FlagKey,
                       default : CustomFields = nil,
                       *,
                       context ctx : EvaluationContext? = nil,
                       options : EvaluationOptions? = nil)
      with_hooks(flag_key, Type::Structure, default, ctx, options) do |merged_ctx|
        details = @provider.resolve_object_value(flag_key, default, merged_ctx)
        FlagEvaluationDetails.new(flag_key, Type::Structure, details)
      end
    end
  end
end
