# frozen_string_literal: true

module Kubeclient
  # An exec-based client auth provide
  # https://kubernetes.io/docs/reference/access-authn-authz/authentication/#configuration
  # Inspired by https://github.com/kubernetes/client-go/blob/master/plugin/pkg/client/auth/exec/exec.go
  class ExecCredentials
    class << self
      def run(opts)
        require 'open3'
        require 'json'

        raise ArgumentError, 'exec options are required' if opts.nil?

        cmd = opts['command']
        args = opts['args']
        env = map_env(opts['env'])

        # Validate exec options
        validate_opts(opts)

        out, err, st = Open3.capture3(env, cmd, *args)

        raise "exec command failed: #{err}" unless st.success?

        creds = JSON.parse(out)
        validate_credentials(opts, creds)
        creds['status']
      end

      private

      def validate_opts(opts)
        raise KeyError, 'exec command is required' unless opts['command']
      end

      def validate_client_credentials_status(status)
        has_client_cert_data = status.key?('clientCertificateData')
        has_client_key_data = status.key?('clientKeyData')

        if has_client_cert_data && !has_client_key_data
          raise 'exec plugin didn\'t return client key data'
        end

        if !has_client_cert_data && has_client_key_data
          raise 'exec plugin didn\'t return client certificate data'
        end

        has_client_cert_data && has_client_key_data
      end

      def validate_credentials_status(status)
        raise 'exec plugin didn\'t return a status field' if status.nil?

        has_client_credentials = validate_client_credentials_status(status)
        has_token = status.key?('token')

        if has_client_credentials && has_token
          raise 'exec plugin returned both token and client data'
        end

        return if has_client_credentials || has_token

        raise 'exec plugin didn\'t return a token or client data' unless has_token
      end

      def validate_credentials(opts, creds)
        # out should have ExecCredential structure
        raise 'invalid credentials' if creds.nil?

        # Verify apiVersion?
        api_version = opts['apiVersion']
        if api_version && api_version != creds['apiVersion']
          raise "exec plugin is configured to use API version #{api_version}, " \
            "plugin returned version #{creds['apiVersion']}"
        end

        validate_credentials_status(creds['status'])
      end

      # Transform name/value pairs to hash
      def map_env(env)
        return {} unless env

        Hash[env.map { |e| [e['name'], e['value']] }]
      end
    end
  end
end
