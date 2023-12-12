module Superset
  module Security
    module User
      class Create < Superset::Request
        attr_reader :user_params

        def initialize(user_params: {})
          @user_params = user_params.with_indifferent_access
        end

        def response
          validate_user_params

          @response ||= client.post(route, user_params)
        end

        def validate_user_params
          raise InvalidParameterError, "Missing user params. Expects #{valid_user_params_keys}" unless symbolized_user_param_keys == valid_user_params_keys
          raise InvalidParameterError, 'Roles must be an array ' unless user_params[:roles].is_a?(Array)
          confirm_all_params_present
        end

        private

        def error_message
          errors = ''
        end

        def confirm_all_params_present
          symbolized_user_param_keys.each do |key|
            raise InvalidParameterError, "Missing #{key}" unless user_params[key].present?
          end
        end

        def symbolized_user_param_keys
          user_params.keys.map(&:to_sym)
        end

        def  valid_user_params_keys
          [ :active, :email, :first_name, :last_name, :password, :roles, :username ]
        end

        def route
          "security/users/"
        end
      end
    end
  end
end
