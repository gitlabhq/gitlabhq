# frozen_string_literal: true

module Kubeclient
  # Generates a bearer token for Google Cloud Platform.
  class GCPCommandCredentials
    class << self
      def token(config)
        require 'open3'
        require 'shellwords'
        require 'json'
        require 'jsonpath'

        cmd = config['cmd-path']
        args = config['cmd-args']
        token_key = config['token-key']

        out, err, st = Open3.capture3(cmd, *args.split(' '))

        raise "exec command failed: #{err}" unless st.success?

        extract_token(out, token_key)
      end

      private

      def extract_token(output, token_key)
        JsonPath.on(output, token_key.gsub(/^{|}$/, '')).first
      end
    end
  end
end
