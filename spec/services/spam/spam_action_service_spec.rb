# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spam::SpamActionService do
  include_context 'includes Spam constants'

  let(:request) { double(:request, env: env, headers: {}) }
  let(:issue) { create(:issue, project: project, author: user) }
  let(:fake_ip) { '1.2.3.4' }
  let(:fake_user_agent) { 'fake-user-agent' }
  let(:fake_referer) { 'fake-http-referer' }
  let(:env) do
    { 'action_dispatch.remote_ip' => fake_ip,
      'HTTP_USER_AGENT' => fake_user_agent,
      'HTTP_REFERER' => fake_referer }
  end

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  before do
    issue.spam = false
  end

  shared_examples 'only checks for spam if a request is provided' do
    context 'when request is missing' do
      let(:request) { nil }

      it "doesn't check as spam" do
        expect(fake_verdict_service).not_to receive(:execute)

        response = subject

        expect(response.message).to match(/request was not present/)
        expect(issue).not_to be_spam
      end
    end

    context 'when request exists' do
      it 'creates a spam log' do
        expect { subject }
          .to log_spam(title: issue.title, description: issue.description, noteable_type: 'Issue')
      end
    end
  end

  shared_examples 'creates a spam log' do
    it do
      expect { subject }.to change(SpamLog, :count).by(1)

      new_spam_log = SpamLog.last
      expect(new_spam_log.user_id).to eq(user.id)
      expect(new_spam_log.title).to eq(issue.title)
      expect(new_spam_log.description).to eq(issue.description)
      expect(new_spam_log.source_ip).to eq(fake_ip)
      expect(new_spam_log.user_agent).to eq(fake_user_agent)
      expect(new_spam_log.noteable_type).to eq('Issue')
      expect(new_spam_log.via_api).to eq(false)
    end
  end

  describe '#execute' do
    let(:request) { double(:request, env: env, headers: nil) }
    let(:fake_captcha_verification_service) { double(:captcha_verification_service) }
    let(:fake_verdict_service) { double(:spam_verdict_service) }
    let(:allowlisted) { false }
    let(:api) { nil }
    let(:captcha_response) { 'abc123' }
    let(:spam_log_id) { existing_spam_log.id }
    let(:spam_params) do
      ::Spam::SpamParams.new(
        api: api,
        captcha_response: captcha_response,
        spam_log_id: spam_log_id
      )
    end

    let(:verdict_service_opts) do
      {
        ip_address: fake_ip,
        user_agent: fake_user_agent,
        referer: fake_referer
      }
    end

    let(:verdict_service_args) do
      {
        target: issue,
        user: user,
        request: request,
        options: verdict_service_opts,
        context: {
          action: :create,
          target_type: 'Issue'
        }
      }
    end

    let_it_be(:existing_spam_log) { create(:spam_log, user: user, recaptcha_verified: false) }

    subject do
      described_service = described_class.new(spammable: issue, request: request, user: user, action: :create)
      allow(described_service).to receive(:allowlisted?).and_return(allowlisted)
      described_service.execute(spam_params: spam_params)
    end

    before do
      allow(Captcha::CaptchaVerificationService).to receive(:new) { fake_captcha_verification_service }
      allow(Spam::SpamVerdictService).to receive(:new).with(verdict_service_args).and_return(fake_verdict_service)
    end

    context 'when the captcha params are passed in the headers' do
      let(:request) { double(:request, env: env, headers: headers) }
      let(:spam_params) { Spam::SpamActionService.filter_spam_params!({ api: api }, request) }
      let(:headers) do
        {
          'X-GitLab-Captcha-Response' => captcha_response,
          'X-GitLab-Spam-Log-Id' => spam_log_id
        }
      end

      it 'extracts the headers correctly' do
        expect(fake_captcha_verification_service)
          .to receive(:execute).with(captcha_response: captcha_response, request: request).and_return(true)
        expect(SpamLog)
          .to receive(:verify_recaptcha!).with(user_id: user.id, id: spam_log_id)

        subject
      end
    end

    context 'when captcha response verification returns true' do
      before do
        allow(fake_captcha_verification_service)
          .to receive(:execute).with(captcha_response: captcha_response, request: request).and_return(true)
      end

      it "doesn't check with the SpamVerdictService" do
        aggregate_failures do
          expect(SpamLog).to receive(:verify_recaptcha!).with(
            user_id: user.id,
            id: spam_log_id
          )
          expect(fake_verdict_service).not_to receive(:execute)
        end

        subject
      end

      it 'updates spam log' do
        expect { subject }.to change { existing_spam_log.reload.recaptcha_verified }.from(false).to(true)
      end
    end

    context 'when captcha response verification returns false' do
      before do
        allow(fake_captcha_verification_service)
          .to receive(:execute).with(captcha_response: captcha_response, request: request).and_return(false)
      end

      context 'when spammable attributes have not changed' do
        before do
          issue.closed_at = Time.zone.now
        end

        it 'does not create a spam log' do
          expect { subject }.not_to change(SpamLog, :count)
        end
      end

      context 'when spammable attributes have changed' do
        let(:expected_service_check_response_message) do
          /Check Issue spammable model for any errors or CAPTCHA requirement/
        end

        before do
          issue.description = 'Lovely Spam! Wonderful Spam!'
        end

        context 'when allowlisted' do
          let(:allowlisted) { true }

          it 'does not perform spam check' do
            expect(Spam::SpamVerdictService).not_to receive(:new)

            response = subject

            expect(response.message).to match(/user was allowlisted/)
          end
        end

        context 'when disallowed by the spam verdict service' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(DISALLOW)
          end

          context 'when allow_possible_spam feature flag is false' do
            before do
              stub_feature_flags(allow_possible_spam: false)
            end

            it_behaves_like 'only checks for spam if a request is provided'

            it 'marks as spam' do
              response = subject

              expect(response.message).to match(expected_service_check_response_message)
              expect(issue).to be_spam
            end
          end

          context 'when allow_possible_spam feature flag is true' do
            it_behaves_like 'only checks for spam if a request is provided'

            it 'does not mark as spam' do
              response = subject

              expect(response.message).to match(expected_service_check_response_message)
              expect(issue).not_to be_spam
            end
          end
        end

        context 'spam verdict service advises to block the user' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(BLOCK_USER)
          end

          context 'when allow_possible_spam feature flag is false' do
            before do
              stub_feature_flags(allow_possible_spam: false)
            end

            it_behaves_like 'only checks for spam if a request is provided'

            it 'marks as spam' do
              response = subject

              expect(response.message).to match(expected_service_check_response_message)
              expect(issue).to be_spam
            end
          end

          context 'when allow_possible_spam feature flag is true' do
            it_behaves_like 'only checks for spam if a request is provided'

            it 'does not mark as spam' do
              response = subject

              expect(response.message).to match(expected_service_check_response_message)
              expect(issue).not_to be_spam
            end
          end
        end

        context 'when spam verdict service conditionally allows' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(CONDITIONAL_ALLOW)
          end

          context 'when allow_possible_spam feature flag is false' do
            before do
              stub_feature_flags(allow_possible_spam: false)
            end

            it_behaves_like 'only checks for spam if a request is provided'

            it_behaves_like 'creates a spam log'

            it 'does not mark as spam' do
              response = subject

              expect(response.message).to match(expected_service_check_response_message)
              expect(issue).not_to be_spam
            end

            it 'marks as needing reCAPTCHA' do
              response = subject

              expect(response.message).to match(expected_service_check_response_message)
              expect(issue).to be_needs_recaptcha
            end
          end

          context 'when allow_possible_spam feature flag is true' do
            it_behaves_like 'only checks for spam if a request is provided'

            it_behaves_like 'creates a spam log'

            it 'does not mark as needing reCAPTCHA' do
              response = subject

              expect(response.message).to match(expected_service_check_response_message)
              expect(issue.needs_recaptcha).to be_falsey
            end
          end
        end

        context 'when spam verdict service allows creation' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(ALLOW)
          end

          it 'does not create a spam log' do
            expect { subject }.not_to change(SpamLog, :count)
          end

          it 'clears spam flags' do
            expect(issue).to receive(:clear_spam_flags!)

            subject
          end
        end

        context 'when spam verdict service returns noop' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(NOOP)
          end

          it 'does not create a spam log' do
            expect { subject }.not_to change(SpamLog, :count)
          end

          it 'clears spam flags' do
            expect(issue).to receive(:clear_spam_flags!)

            subject
          end
        end

        context 'with spam verdict service options' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(ALLOW)
          end

          context 'when the request is nil' do
            let(:request) { nil }
            let(:issue_ip_address) { '1.2.3.4' }
            let(:issue_user_agent) { 'lynx' }
            let(:verdict_service_opts) do
              {
                ip_address: issue_ip_address,
                user_agent: issue_user_agent
              }
            end

            before do
              allow(issue).to receive(:ip_address) { issue_ip_address }
              allow(issue).to receive(:user_agent) { issue_user_agent }
            end

            it 'assembles the options with information from the spammable' do
              # TODO: This code untestable, because we do not perform a verification if there is not a
              #   request. See corresponding comment in code
              # expect(Spam::SpamVerdictService).to receive(:new).with(verdict_service_args)

              subject
            end
          end

          context 'when the request is present' do
            it 'assembles the options with information from the request' do
              expect(Spam::SpamVerdictService).to receive(:new).with(verdict_service_args)

              subject
            end
          end
        end
      end
    end
  end
end
