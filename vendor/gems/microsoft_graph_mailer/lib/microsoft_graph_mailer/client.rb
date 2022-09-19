# frozen_string_literal: true

require "oauth2"

module MicrosoftGraphMailer
  class Client
    attr_accessor :user_id, :tenant, :client_id, :client_secret, :azure_ad_endpoint, :graph_endpoint

    def initialize(user_id:, tenant:, client_id:, client_secret:, azure_ad_endpoint:, graph_endpoint:)
      @user_id = user_id
      @tenant = tenant
      @client_id = client_id
      @client_secret = client_secret
      @azure_ad_endpoint = azure_ad_endpoint
      @graph_endpoint = graph_endpoint
    end

    def send_mail(message_in_mime_format)
      # https://docs.microsoft.com/en-us/graph/api/user-sendmail
      token.post(
        send_mail_url,
        headers: { "Content-type" => "text/plain" },
        body: Base64.encode64(message_in_mime_format)
      )
    end

    private

    def token
      # https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-client-creds-grant-flow
      OAuth2::Client.new(
        client_id,
        client_secret,
        site: azure_ad_endpoint,
        token_url: "/#{tenant}/oauth2/v2.0/token"
      ).client_credentials.get_token({ scope: scope })
    end

    def scope
      "#{graph_endpoint}/.default"
    end

    def base_url
      "#{graph_endpoint}/v1.0/users/#{user_id}"
    end

    def send_mail_url
      "#{base_url}/sendMail"
    end
  end
end
