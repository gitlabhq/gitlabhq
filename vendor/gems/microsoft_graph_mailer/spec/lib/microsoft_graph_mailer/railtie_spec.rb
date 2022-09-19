# frozen_string_literal: true

require "spec_helper"

require "securerandom"

class TestMailer < ActionMailer::Base
  def gitlab_mission(to:, cc: [])
    mail(from: "about@gitlab.com", to: to, cc: cc, subject: "GitLab Mission") do |format|
      format.text { render plain: "It is GitLab's mission to make it so that everyone can contribute." }
      format.html { render html: "It is GitLab's mission to make it so that <strong>everyone can contribute</strong>.".html_safe }
    end

    mail.attachments["gitlab.txt"] = File.read(fixture_path("attachments", "gitlab.txt"))

    mail.attachments["gitlab_logo.png"] = File.read(fixture_path("attachments", "gitlab_logo.png"))
  end
end

RSpec.describe MicrosoftGraphMailer::Railtie do
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

  let(:message) { TestMailer.gitlab_mission(to: "to@example.com", cc: "cc@example.com") }

  before do
    ActionMailer::Base.delivery_method = :microsoft_graph
    ActionMailer::Base.microsoft_graph_settings = microsoft_graph_settings
  end

  it "its superclass is Rails::Railtie" do
    expect(MicrosoftGraphMailer::Railtie.superclass).to eq(Rails::Railtie)
  end

  describe "settings" do
    describe "ActionMailer::Base.delivery_methods[:microsoft_graph]" do
      it "returns MicrosoftGraphMailer::Delivery" do
        expect(ActionMailer::Base.delivery_methods[:microsoft_graph]).to eq(MicrosoftGraphMailer::Delivery)
      end
    end

    describe "ActionMailer::Base.microsoft_graph_settings" do
      it "returns microsoft_graph_settings" do
        expect(ActionMailer::Base.microsoft_graph_settings).to eq(microsoft_graph_settings)
      end
    end

    it "sets #microsoft_graph_settings" do
      expect(message.delivery_method.microsoft_graph_settings).to eq(microsoft_graph_settings)
    end

    [:user_id, :tenant, :client_id, :client_secret].each do |setting|
      it "raises MicrosoftGraphMailer::ConfigurationError when '#{setting}' is missing" do
        microsoft_graph_settings[setting] = nil
        ActionMailer::Base.microsoft_graph_settings = microsoft_graph_settings

        expect { message.delivery_method }
          .to raise_error(MicrosoftGraphMailer::ConfigurationError, "'#{setting}' is missing")
      end
    end

    it "sets azure_ad_endpoint setting to 'https://login.microsoftonline.com' when it is missing" do
      microsoft_graph_settings[:azure_ad_endpoint] = nil
      ActionMailer::Base.microsoft_graph_settings = microsoft_graph_settings

      expect(message.delivery_method.microsoft_graph_settings[:azure_ad_endpoint]).to eq("https://login.microsoftonline.com")
    end

    it "sets graph_endpoint setting to 'https://graph.microsoft.com' when it is missing" do
      microsoft_graph_settings[:graph_endpoint] = nil
      ActionMailer::Base.microsoft_graph_settings = microsoft_graph_settings

      expect(message.delivery_method.microsoft_graph_settings[:graph_endpoint]).to eq("https://graph.microsoft.com")
    end
  end

  describe "ActionMailer::MessageDelivery#deliver_now" do
    let(:access_token) { SecureRandom.hex }

    context "when token request is successful" do
      before do
        stub_token_request(microsoft_graph_settings: microsoft_graph_settings, access_token: access_token, response_status: 200)
      end

      context "when send mail request returns response status 202" do
        it "sends and returns mail" do
          stub_send_mail_request(microsoft_graph_settings: microsoft_graph_settings, access_token: access_token, message: message, response_status: 202)

          expect(message.deliver_now).to eq(message)
        end

        it "sends mail including bcc field" do
          message.bcc = "bcc@example.com"

          stub_send_mail_request(microsoft_graph_settings: microsoft_graph_settings, access_token: access_token, message: message, response_status: 202)

          message.deliver_now
        end

        it "does not change message[:bcc].include_in_headers" do
          message.bcc = "bcc@example.com"
          expected_message_bcc_include_in_headers = "42"
          message[:bcc].include_in_headers = expected_message_bcc_include_in_headers

          stub_send_mail_request(microsoft_graph_settings: microsoft_graph_settings, access_token: access_token, message: message, response_status: 202)

          message.deliver_now

          expect(message[:bcc].include_in_headers).to eq(expected_message_bcc_include_in_headers)
        end
      end

      context "when send mail request returns response status other than 202" do
        it "raises MicrosoftGraphMailer::DeliveryError" do
          stub_send_mail_request(microsoft_graph_settings: microsoft_graph_settings, access_token: access_token, message: message, response_status: 200)

          expect { message.deliver_now }.to raise_error(MicrosoftGraphMailer::DeliveryError)
        end
      end
    end

    context "when token request is not successful" do
      before do
        stub_token_request(microsoft_graph_settings: microsoft_graph_settings, access_token: access_token, response_status: 503)
      end

      it "raises OAuth2::Error" do
        expect { message.deliver_now }.to raise_error(OAuth2::Error)
      end
    end
  end
end
