# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::MailRoom, feature_category: :service_desk do
  let(:base_configs) do
    {
      enabled: true,
      address: 'address@example.com',
      port: 143,
      ssl: false,
      start_tls: false,
      mailbox: 'inbox',
      idle_timeout: 60,
      log_path: Rails.root.join('log', 'mail_room_json.log').to_s,
      expunge_deleted: false
    }
  end

  let(:enabled_configs) do
    {
      incoming_email: base_configs.merge(
        secure_file: Rails.root.join('tmp', 'tests', '.incoming_email_secret').to_s
      ),
      service_desk_email: base_configs.merge(
        secure_file: Rails.root.join('tmp', 'tests', '.service_desk_email').to_s
      )
    }
  end

  let(:auth_payload) { { 'iss' => Gitlab::MailRoom::INTERNAL_API_REQUEST_JWT_ISSUER, 'iat' => (Time.now - 10.seconds).to_i } }

  let(:incoming_email_secret) { 'incoming_email_secret' }
  let(:service_desk_email_secret) { 'service_desk_email_secret' }

  let(:email_content) { fixture_file("emails/service_desk_reply.eml") }

  before do
    allow(Gitlab::MailRoom::Authenticator).to receive(:secret).with(:incoming_email).and_return(incoming_email_secret)
    allow(Gitlab::MailRoom::Authenticator).to receive(:secret).with(:service_desk_email).and_return(service_desk_email_secret)
    allow(Gitlab::MailRoom).to receive(:enabled_configs).and_return(enabled_configs)
  end

  around do |example|
    freeze_time do
      example.run
    end
  end

  describe "POST /internal/mail_room/*mailbox_type" do
    context 'handle incoming_email successfully' do
      let(:auth_headers) do
        jwt_token = JWT.encode(auth_payload, incoming_email_secret, 'HS256')
        { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => jwt_token }
      end

      it 'schedules a EmailReceiverWorker job with raw email content' do
        Sidekiq::Testing.fake! do
          expect do
            post api("/internal/mail_room/incoming_email"), headers: auth_headers, params: email_content
          end.to change { EmailReceiverWorker.jobs.size }.by(1)
        end

        expect(response).to have_gitlab_http_status(:ok)

        job = EmailReceiverWorker.jobs.last
        expect(job).to match a_hash_including('args' => [email_content])
      end
    end

    context 'handle service_desk_email successfully' do
      let(:auth_headers) do
        jwt_token = JWT.encode(auth_payload, service_desk_email_secret, 'HS256')
        { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => jwt_token }
      end

      it 'schedules a ServiceDeskEmailReceiverWorker job with raw email content' do
        Sidekiq::Testing.fake! do
          expect do
            post api("/internal/mail_room/service_desk_email"), headers: auth_headers, params: email_content
          end.to change { ServiceDeskEmailReceiverWorker.jobs.size }.by(1)
        end

        expect(response).to have_gitlab_http_status(:ok)

        job = ServiceDeskEmailReceiverWorker.jobs.last
        expect(job).to match a_hash_including('args' => [email_content])
      end
    end

    context 'email content exceeds limit' do
      let(:auth_headers) do
        jwt_token = JWT.encode(auth_payload, incoming_email_secret, 'HS256')
        { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => jwt_token }
      end

      before do
        allow(EmailReceiverWorker).to receive(:perform_async).and_raise(
          Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError.new(EmailReceiverWorker, email_content.bytesize, email_content.bytesize - 1)
        )
      end

      it 'responds with 400 bad request and replies with a failure message' do
        perform_enqueued_jobs do
          Sidekiq::Testing.fake! do
            expect do
              post api("/internal/mail_room/incoming_email"), headers: auth_headers, params: email_content
            end.not_to change { EmailReceiverWorker.jobs.size }
          end
        end

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(Gitlab::Json.parse(response.body)).to match a_hash_including(
          "success" => false,
          "message" => "We couldn't process your email because it is too large. Please create your issue or comment through the web interface."
        )

        email = ActionMailer::Base.deliveries.last
        expect(email).not_to be_nil
        expect(email.to).to match_array(["alan@adventuretime.ooo"])
        expect(email.subject).to include("Rejected")
        expect(email.body.parts.last.to_s).to include("We couldn't process your email")
      end
    end

    context 'not authenticated' do
      it 'responds with 401 Unauthorized' do
        post api("/internal/mail_room/incoming_email")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'wrong token authentication' do
      let(:auth_headers) do
        jwt_token = JWT.encode(auth_payload, 'wrongsecret', 'HS256')
        { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => jwt_token }
      end

      it 'responds with 401 Unauthorized' do
        post api("/internal/mail_room/incoming_email"), headers: auth_headers

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'wrong mailbox type authentication' do
      let(:auth_headers) do
        jwt_token = JWT.encode(auth_payload, service_desk_email_secret, 'HS256')
        { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => jwt_token }
      end

      it 'responds with 401 Unauthorized' do
        post api("/internal/mail_room/incoming_email"), headers: auth_headers

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'not supported mailbox type' do
      let(:auth_headers) do
        jwt_token = JWT.encode(auth_payload, incoming_email_secret, 'HS256')
        { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => jwt_token }
      end

      it 'responds with 401 Unauthorized' do
        post api("/internal/mail_room/invalid_mailbox_type"), headers: auth_headers

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'not enabled mailbox type' do
      let(:enabled_configs) do
        {
          incoming_email: base_configs.merge(
            secure_file: Rails.root.join('tmp', 'tests', '.incoming_email_secret').to_s
          )
        }
      end

      let(:auth_headers) do
        jwt_token = JWT.encode(auth_payload, service_desk_email_secret, 'HS256')
        { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => jwt_token }
      end

      it 'responds with 401 Unauthorized' do
        post api("/internal/mail_room/service_desk_email"), headers: auth_headers

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'handle invalid utf-8 email content' do
      let(:email_content) do
        File.open(expand_fixture_path("emails/service_desk_reply_illegal_utf8.eml"), "r:SHIFT_JIS") { |f| f.read }
      end

      let(:encoded_email_content) { Gitlab::EncodingHelper.encode_utf8(email_content) }
      let(:auth_headers) do
        jwt_token = JWT.encode(auth_payload, incoming_email_secret, 'HS256')
        { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => jwt_token }
      end

      it 'schedules a EmailReceiverWorker job with email content encoded to utf-8 forcefully' do
        Sidekiq::Testing.fake! do
          expect do
            post api("/internal/mail_room/incoming_email"), headers: auth_headers, params: email_content
          end.to change { EmailReceiverWorker.jobs.size }.by(1)
        end

        expect(response).to have_gitlab_http_status(:ok)

        job = EmailReceiverWorker.jobs.last
        expect(job).to match a_hash_including('args' => [encoded_email_content])
      end
    end

    context 'handle text/plain request content type' do
      let(:auth_headers) do
        jwt_token = JWT.encode(auth_payload, incoming_email_secret, 'HS256')
        {
          Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => jwt_token,
          'Content-Type' => 'text/plain'
        }
      end

      it 'schedules a EmailReceiverWorker job with email content encoded to utf-8 forcefully' do
        Sidekiq::Testing.fake! do
          expect do
            post api("/internal/mail_room/incoming_email"), headers: auth_headers, params: email_content
          end.to change { EmailReceiverWorker.jobs.size }.by(1)
        end

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.content_type).to eql('application/json')

        job = EmailReceiverWorker.jobs.last
        expect(job).to match a_hash_including('args' => [email_content])
      end
    end
  end
end
