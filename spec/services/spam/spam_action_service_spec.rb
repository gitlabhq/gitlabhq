# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spam::SpamActionService do
  include_context 'includes Spam constants'

  let(:issue) { create(:issue, project: project, author: author) }
  let(:fake_ip) { '1.2.3.4' }
  let(:fake_user_agent) { 'fake-user-agent' }
  let(:fake_referer) { 'fake-http-referer' }
  let(:captcha_response) { 'abc123' }
  let(:spam_log_id) { existing_spam_log.id }
  let(:spam_params) do
    ::Spam::SpamParams.new(
      captcha_response: captcha_response,
      spam_log_id: spam_log_id,
      ip_address: fake_ip,
      user_agent: fake_user_agent,
      referer: fake_referer
    )
  end

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user) }

  before do
    issue.spam = false
  end

  describe 'constructor argument validation' do
    subject do
      described_service = described_class.new(spammable: issue, spam_params: spam_params, user: user, action: :create)
      described_service.execute
    end

    context 'when spam_params is nil' do
      let(:spam_params) { nil }
      let(:expected_service_params_not_present_message) do
        /Skipped spam check because spam_params was not present/
      end

      it "returns success with a messaage" do
        response = subject

        expect(response.message).to match(expected_service_params_not_present_message)
        expect(issue).not_to be_spam
      end
    end
  end

  shared_examples 'creates a spam log' do
    it do
      expect { subject }
        .to log_spam(title: issue.title, description: issue.description, noteable_type: 'Issue')

      # TODO: These checks should be incorporated into the `log_spam` RSpec matcher above
      new_spam_log = SpamLog.last
      expect(new_spam_log.user_id).to eq(user.id)
      expect(new_spam_log.title).to eq(issue.title)
      expect(new_spam_log.description).to eq(issue.description)
      expect(new_spam_log.source_ip).to eq(fake_ip)
      expect(new_spam_log.user_agent).to eq(fake_user_agent)
      expect(new_spam_log.noteable_type).to eq('Issue')
      expect(new_spam_log.via_api).to eq(true)
    end
  end

  describe '#execute' do
    let(:fake_captcha_verification_service) { double(:captcha_verification_service) }
    let(:fake_verdict_service) { double(:spam_verdict_service) }
    let(:allowlisted) { false }

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
        options: verdict_service_opts,
        context: {
          action: :create,
          target_type: 'Issue'
        }
      }
    end

    let_it_be(:existing_spam_log) { create(:spam_log, user: user, recaptcha_verified: false) }

    subject do
      described_service = described_class.new(spammable: issue, spam_params: spam_params, user: user, action: :create)
      allow(described_service).to receive(:allowlisted?).and_return(allowlisted)
      described_service.execute
    end

    before do
      allow(Captcha::CaptchaVerificationService).to receive(:new).with(spam_params: spam_params) { fake_captcha_verification_service }
      allow(Spam::SpamVerdictService).to receive(:new).with(verdict_service_args).and_return(fake_verdict_service)
    end

    context 'when captcha response verification returns true' do
      before do
        allow(fake_captcha_verification_service)
          .to receive(:execute).and_return(true)
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
          .to receive(:execute).and_return(false)
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

            it 'marks as spam' do
              response = subject

              expect(response.message).to match(expected_service_check_response_message)
              expect(issue).to be_spam
            end
          end

          context 'when allow_possible_spam feature flag is true' do
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

            it 'marks as spam' do
              response = subject

              expect(response.message).to match(expected_service_check_response_message)
              expect(issue).to be_spam
            end
          end

          context 'when allow_possible_spam feature flag is true' do
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

          it 'assembles the options with information from the request' do
            expect(Spam::SpamVerdictService).to receive(:new).with(verdict_service_args)

            subject
          end
        end
      end
    end
  end
end
