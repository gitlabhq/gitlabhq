# frozen_string_literal: true

require "spec_helper"

require "securerandom"

RSpec.describe MicrosoftGraphMailer::Delivery do
  let(:microsoft_graph_settings) do
    {
      user_id: SecureRandom.hex,
      tenant: SecureRandom.hex,
      client_id: SecureRandom.hex,
      client_secret: SecureRandom.hex,
      azure_ad_endpoint: "https://test-azure_ad_endpoint",
      graph_endpoint: "https://test-graph_endpoint"
    }
  end

  subject { described_class.new(microsoft_graph_settings) }

  describe ".new" do
    it "sets #microsoft_graph_settings" do
      expect(subject.microsoft_graph_settings).to eq(microsoft_graph_settings)
    end

    [:user_id, :tenant, :client_id, :client_secret].each do |setting|
      it "raises MicrosoftGraphMailer::ConfigurationError when '#{setting}' is missing" do
        microsoft_graph_settings[setting] = nil

        expect { subject }
          .to raise_error(MicrosoftGraphMailer::ConfigurationError, "'#{setting}' is missing")
      end
    end

    it "sets azure_ad_endpoint setting to 'https://login.microsoftonline.com' when it is missing" do
      microsoft_graph_settings[:azure_ad_endpoint] = nil

      expect(subject.microsoft_graph_settings[:azure_ad_endpoint]).to eq("https://login.microsoftonline.com")
    end

    it "sets graph_endpoint setting to 'https://graph.microsoft.com' when it is missing" do
      microsoft_graph_settings[:graph_endpoint] = nil

      expect(subject.microsoft_graph_settings[:graph_endpoint]).to eq("https://graph.microsoft.com")
    end
  end

  describe "#deliver!" do
    let(:access_token) { SecureRandom.hex }

    let(:message) do
      Mail.new do
        from "about@gitlab.com"

        to "to@example.com"

        cc "cc@example.com"

        subject "GitLab Mission"

        text_part do
          body "It is GitLab's mission to make it so that everyone can contribute."
        end

        html_part do
          content_type "text/html; charset=UTF-8"
          body "It is GitLab's mission to make it so that <strong>everyone can contribute</strong>."
        end

        add_file fixture_path("attachments", "gitlab.txt")

        add_file fixture_path("attachments", "gitlab_logo.png")
      end
    end

    context "when token request is successful" do
      before do
        stub_token_request(microsoft_graph_settings: subject.microsoft_graph_settings, access_token: access_token, response_status: 200)
      end

      context "when send mail request returns response status 202" do
        it "sends mail and returns an instance of OAuth2::Response" do
          stub_send_mail_request(microsoft_graph_settings: subject.microsoft_graph_settings, access_token: access_token, message: message, response_status: 202)

          expect(subject.deliver!(message)).to be_an_instance_of(OAuth2::Response)
        end

        it "sends mail including bcc field" do
          message.bcc = "bcc@example.com"

          stub_send_mail_request(microsoft_graph_settings: subject.microsoft_graph_settings, access_token: access_token, message: message, response_status: 202)

          subject.deliver!(message)
        end

        it "does not change message[:bcc].include_in_headers" do
          message.bcc = "bcc@example.com"
          expected_message_bcc_include_in_headers = "42"
          message[:bcc].include_in_headers = expected_message_bcc_include_in_headers

          stub_send_mail_request(microsoft_graph_settings: subject.microsoft_graph_settings, access_token: access_token, message: message, response_status: 202)

          subject.deliver!(message)

          expect(message[:bcc].include_in_headers).to eq(expected_message_bcc_include_in_headers)
        end
      end

      context "when send mail request returns response status other than 202" do
        it "raises MicrosoftGraphMailer::DeliveryError" do
          stub_send_mail_request(microsoft_graph_settings: subject.microsoft_graph_settings, access_token: access_token, message: message, response_status: 200)

          expect { subject.deliver!(message) }.to raise_error(MicrosoftGraphMailer::DeliveryError)
        end
      end
    end

    context "when token request is not successful" do
      before do
        stub_token_request(microsoft_graph_settings: subject.microsoft_graph_settings, access_token: access_token, response_status: 503)
      end

      it "raises OAuth2::Error" do
        expect { subject.deliver!(message) }.to raise_error(OAuth2::Error)
      end
    end
  end
end
