# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spam::SpamActionService, feature_category: :instance_resiliency do
  include_context 'includes Spam constants'

  let(:issue) { create(:issue, project: project, author: author) }
  let(:personal_snippet) { create(:personal_snippet, :public, author: author) }
  let(:project_snippet) { create(:project_snippet, :public, author: author) }
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
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be(:author) { create(:user) }

  before do
    issue.spam = false
    personal_snippet.spam = false

    allow_next_instance_of(described_class) do |service|
      allow(service).to receive(:spam_params).and_return(spam_params)
    end
  end

  describe 'constructor argument validation' do
    subject do
      described_service = described_class.new(spammable: issue, user: user, action: :create)
      described_service.execute
    end

    context 'when user is nil' do
      let(:spam_params) { true }
      let(:user) { nil }
      let(:expected_service_user_not_present_message) do
        /Skipped spam check because user was not present/
      end

      it "returns success with a messaage" do
        response = subject

        expect(response.message).to match(expected_service_user_not_present_message)
        expect(issue).not_to be_spam
      end
    end
  end

  shared_examples 'allows user' do
    it 'does not perform spam check' do
      expect(Spam::SpamVerdictService).not_to receive(:new)

      response = subject

      expect(response.message).to match(/user was allowlisted/)
    end
  end

  shared_examples 'creates a spam log' do |target_type|
    it do
      expect { subject }
        .to log_spam(title: target.title, description: target.description, noteable_type: target_type)

      # TODO: These checks should be incorporated into the `log_spam` RSpec matcher above
      new_spam_log = SpamLog.last
      expect(new_spam_log.user_id).to eq(user.id)
      expect(new_spam_log.title).to eq(target.title)
      expect(new_spam_log.description).to eq(target.spam_description)
      expect(new_spam_log.source_ip).to eq(fake_ip)
      expect(new_spam_log.user_agent).to eq(fake_user_agent)
      expect(new_spam_log.noteable_type).to eq(target_type)
      expect(new_spam_log.via_api).to eq(true)
    end
  end

  shared_examples 'calls SpamAbuseEventsWorker with correct arguments' do
    let(:params) do
      {
        user_id: user.id,
        title: target.title,
        description: target.spam_description,
        source_ip: fake_ip,
        user_agent: fake_user_agent,
        noteable_type: target_type,
        verdict: verdict
      }
    end

    it 'executes the ::AntiAbuse::SpamAbuseEventsWorker' do
      expect(::AntiAbuse::SpamAbuseEventsWorker).to receive(:perform_async).with(params)

      subject
    end
  end

  shared_examples 'does not execute the SpamAbuseEventsWorker' do
    specify do
      expect(::AntiAbuse::SpamAbuseEventsWorker).not_to receive(:perform_async)

      subject
    end
  end

  shared_examples 'allows the spammable' do
    it 'does not create a spam log' do
      expect { subject }.not_to change(SpamLog, :count)
    end

    it_behaves_like 'does not execute the SpamAbuseEventsWorker'

    it 'clears spam flags' do
      expect(target).to receive(:clear_spam_flags!)

      subject
    end
  end

  shared_examples 'execute spam action service' do |target_type|
    let(:fake_captcha_verification_service) { double(:captcha_verification_service) }
    let(:fake_verdict_service) { double(:spam_verdict_service) }

    let(:verdict_service_opts) do
      {
        ip_address: fake_ip,
        user_agent: fake_user_agent,
        referer: fake_referer
      }
    end

    let(:verdict_service_args) do
      {
        target: target,
        user: user,
        options: verdict_service_opts,
        context: {
          action: :create,
          target_type: target_type
        },
        extra_features: extra_features
      }
    end

    let_it_be(:existing_spam_log) { create(:spam_log, user: user, recaptcha_verified: false) }

    subject do
      described_service = described_class.new(spammable: target, extra_features:
                                              extra_features, user: user, action: :create)
      described_service.execute
    end

    before do
      allow(Captcha::CaptchaVerificationService).to receive(:new).with(spam_params: spam_params) { fake_captcha_verification_service }
      allow(Spam::SpamVerdictService).to receive(:new).with(verdict_service_args).and_return(fake_verdict_service)
      allow(fake_verdict_service).to receive(:execute).and_return({})
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
          allow(target).to receive(:has_changes_to_save?).and_return(true)
        end

        it 'does not create a spam log' do
          expect { subject }.not_to change(SpamLog, :count)
        end

        it_behaves_like 'does not execute the SpamAbuseEventsWorker'
      end

      context 'when spammable attributes have changed' do
        let(:expected_service_check_response_message) do
          /Check #{target_type} spammable model for any errors or CAPTCHA requirement/
        end

        before do
          target.description = 'Lovely Spam! Wonderful Spam!'
        end

        context 'when captcha is not supported' do
          before do
            allow(target).to receive(:supports_recaptcha?).and_return(false)
          end

          it "does not execute with captcha support" do
            expect(Captcha::CaptchaVerificationService).not_to receive(:new)

            subject
          end

          it "executes a spam check" do
            expect(fake_verdict_service).to receive(:execute)

            subject
          end
        end

        context 'when user is a gitlab bot' do
          before do
            allow(user).to receive(:gitlab_bot?).and_return(true)
          end

          it_behaves_like 'allows user'
        end

        context 'when user is a gitlab service user' do
          before do
            allow(user).to receive(:gitlab_service_user?).and_return(true)
          end

          it_behaves_like 'allows user'
        end

        context 'when disallowed by the spam verdict service' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(DISALLOW)
          end

          it_behaves_like 'creates a spam log', target_type

          it_behaves_like 'calls SpamAbuseEventsWorker with correct arguments' do
            let(:verdict) { DISALLOW }
            let(:target_type) { target_type }
          end

          it 'marks as spam' do
            response = subject

            expect(response.message).to match(expected_service_check_response_message)
            expect(target).to be_spam
          end
        end

        context 'spam verdict service advises to block the user' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(BLOCK_USER)
          end

          it_behaves_like 'creates a spam log', target_type

          it_behaves_like 'calls SpamAbuseEventsWorker with correct arguments' do
            let(:verdict) { BLOCK_USER }
            let(:target_type) { target_type }
          end

          it 'marks as spam' do
            response = subject

            expect(response.message).to match(expected_service_check_response_message)
            expect(target).to be_spam
          end

          it 'bans the user' do
            expect_next_instance_of(Users::AutoBanService, user: user, reason: 'spam') do |instance|
              expect(instance).to receive(:execute).and_call_original
            end

            subject

            custom_attribute = user.custom_attributes.by_key(UserCustomAttribute::AUTO_BANNED_BY_SPAM_LOG_ID).first
            expect(custom_attribute.value).to eq(target.spam_log.id.to_s)
            expect(user).to be_banned
          end
        end

        context 'when spam verdict service conditionally allows' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(CONDITIONAL_ALLOW)
          end

          it_behaves_like 'creates a spam log', target_type

          it_behaves_like 'calls SpamAbuseEventsWorker with correct arguments' do
            let(:verdict) { CONDITIONAL_ALLOW }
            let(:target_type) { target_type }
          end

          it 'does not mark as spam' do
            response = subject

            expect(response.message).to match(expected_service_check_response_message)
            expect(target).not_to be_spam
          end

          it 'marks as needing reCAPTCHA' do
            response = subject

            expect(response.message).to match(expected_service_check_response_message)
            expect(target).to be_needs_recaptcha
          end
        end

        context 'when spam verdict service returns OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM)
          end

          it_behaves_like 'creates a spam log', target_type
          it_behaves_like 'does not execute the SpamAbuseEventsWorker'

          it 'does not mark as spam' do
            response = subject

            expect(response.message).to match(expected_service_check_response_message)
            expect(target).not_to be_spam
          end

          it 'does not mark as needing CAPTCHA' do
            response = subject

            expect(response.message).to match(expected_service_check_response_message)
            expect(target).not_to be_needs_recaptcha
          end
        end

        context 'when spam verdict service allows creation' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(ALLOW)
          end

          it_behaves_like 'allows the spammable'
        end

        context 'when spam verdict service returns noop' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(NOOP)
          end

          it_behaves_like 'allows the spammable'
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

  describe '#execute' do
    describe 'issue' do
      let(:target) { issue }
      let(:extra_features) { {} }

      it_behaves_like 'execute spam action service', 'Issue'
    end

    describe 'project snippet' do
      let(:target) { project_snippet }
      let(:extra_features) { { files: [{ path: 'project.rb' }] } }

      it_behaves_like 'execute spam action service', 'ProjectSnippet'
    end

    describe 'personal snippet' do
      let(:target) { personal_snippet }
      let(:extra_features) { { files: [{ path: 'personal.rb' }] } }

      it_behaves_like 'execute spam action service', 'PersonalSnippet'
    end
  end
end
