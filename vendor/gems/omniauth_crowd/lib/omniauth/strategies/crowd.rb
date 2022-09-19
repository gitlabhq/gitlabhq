require 'omniauth'
require 'active_support'
require 'active_support/core_ext/object'
module OmniAuth
  module Strategies
    class Crowd
      include OmniAuth::Strategy

      autoload :Configuration, 'omniauth/strategies/crowd/configuration'
      autoload :CrowdValidator, 'omniauth/strategies/crowd/crowd_validator'
      def initialize(app, options = {}, &block)
        options.symbolize_keys!()
        super(app, {:name=> :crowd}.merge(options), &block)
        @configuration = OmniAuth::Strategies::Crowd::Configuration.new(options)
      end

      protected

      def request_phase
        if (env['REQUEST_METHOD'] == 'POST') && (not request.params['username'])
          get_credentials
        else
          session['omniauth.crowd'] = {'username' => request['username'], 'password' => request['password']}
          redirect callback_url
        end
      end

      def get_client_ip
        env['HTTP_X_FORWARDED_FOR'] ? env['HTTP_X_FORWARDED_FOR'] : env['REMOTE_ADDRESS']
      end

      def get_sso_tokens
        env['HTTP_COOKIE'].split(';').select { |val| 
          val.strip.start_with?(@configuration.session_cookie)
        }.map { |val| 
          val.strip.split('=').last
        }            
      end

      def get_credentials

        configuration = @configuration

        OmniAuth::Form.build(:title => (options[:title] || "Crowd Authentication")) do
          text_field 'Login', 'username'
          password_field 'Password', 'password'

          if configuration.use_sessions? && configuration.sso_url
            fieldset 'SSO' do
              html "<a href=\"#{configuration.sso_url}/users/auth/crowd/callback\">" + (configuration.sso_url_image ? "<img src=\"#{configuration.sso_url_image}\" />" : '') + "</a>"
            end
          end

        end.to_response

      end
      
      def callback_phase

        creds = session.delete 'omniauth.crowd'
        username = creds.nil? ? nil : creds['username']
        password = creds.nil? ? nil : creds['password']

        unless creds
          if @configuration.use_sessions? && request.cookies[@configuration.session_cookie]
            validator = CrowdValidator.new(@configuration, username, password, get_client_ip, get_sso_tokens)
          else
            return fail!(:no_credentials)
          end
        else
          validator = CrowdValidator.new(@configuration, username, password, get_client_ip, nil)
        end

        @user_info = validator.user_info

        return fail!(:invalid_credentials) if @user_info.nil? || @user_info.empty?

        super
      end

      def auth_hash
        OmniAuth::Utils.deep_merge(super, {
          'uid' => @user_info.delete("user"),
          'info' => @user_info
        })
      end
    end
  end
end
