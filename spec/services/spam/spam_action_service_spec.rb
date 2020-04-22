# frozen_string_literal: true

require 'spec_helper'

describe Spam::SpamActionService do
  include_context 'includes Spam constants'

  let(:fake_ip) { '1.2.3.4' }
  let(:fake_user_agent) { 'fake-user-agent' }
  let(:fake_referrer) { 'fake-http-referrer' }
  let(:env) do
    { 'action_dispatch.remote_ip' => fake_ip,
      'HTTP_USER_AGENT' => fake_user_agent,
      'HTTP_REFERRER' => fake_referrer }
  end
  let(:request) { double(:request, env: env) }

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let(:issue) { create(:issue, project: project, author: user) }

  before do
    issue.spam = false
  end

  describe '#initialize' do
    subject { described_class.new(spammable: issue, request: request) }

    context 'when the request is nil' do
      let(:request) { nil }

      it 'assembles the options with information from the spammable' do
        aggregate_failures do
          expect(subject.options[:ip_address]).to eq(issue.ip_address)
          expect(subject.options[:user_agent]).to eq(issue.user_agent)
          expect(subject.options.key?(:referrer)).to be_falsey
        end
      end
    end

    context 'when the request is present' do
      let(:request) { double(:request, env: env) }

      it 'assembles the options with information from the spammable' do
        aggregate_failures do
          expect(subject.options[:ip_address]).to eq(fake_ip)
          expect(subject.options[:user_agent]).to eq(fake_user_agent)
          expect(subject.options[:referrer]).to eq(fake_referrer)
        end
      end
    end
  end

  shared_examples 'only checks for spam if a request is provided' do
    context 'when request is missing' do
      subject { described_class.new(spammable: issue, request: nil) }

      it "doesn't check as spam" do
        subject

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

  describe '#execute' do
    let(:request) { double(:request, env: env) }
    let(:fake_verdict_service) { double(:spam_verdict_service) }

    let_it_be(:existing_spam_log) { create(:spam_log, user: user, recaptcha_verified: false) }

    subject do
      described_service = described_class.new(spammable: issue, request: request)
      described_service.execute(user_id: user.id, api: nil, recaptcha_verified: recaptcha_verified, spam_log_id: existing_spam_log.id)
    end

    before do
      allow(Spam::SpamVerdictService).to receive(:new).and_return(fake_verdict_service)
    end

    context 'when reCAPTCHA was already verified' do
      let(:recaptcha_verified) { true }

      it "doesn't check with the SpamVerdictService" do
        aggregate_failures do
          expect(SpamLog).to receive(:verify_recaptcha!)
          expect(fake_verdict_service).not_to receive(:execute)
        end

        subject
      end

      it 'updates spam log' do
        expect { subject }.to change { existing_spam_log.reload.recaptcha_verified }.from(false).to(true)
      end
    end

    context 'when reCAPTCHA was not verified' do
      let(:recaptcha_verified) { false }

      context 'when spammable attributes have not changed' do
        before do
          issue.closed_at = Time.zone.now
        end

        it 'does not create a spam log' do
          expect { subject }
            .not_to change { SpamLog.count }
        end
      end

      context 'when spammable attributes have changed' do
        before do
          issue.description = 'SPAM!'
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
              subject

              expect(issue).to be_spam
            end
          end

          context 'when allow_possible_spam feature flag is true' do
            it_behaves_like 'only checks for spam if a request is provided'

            it 'does not mark as spam' do
              subject

              expect(issue).not_to be_spam
            end
          end
        end

        context 'when spam verdict service requires reCAPTCHA' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(REQUIRE_RECAPTCHA)
          end

          context 'when allow_possible_spam feature flag is false' do
            before do
              stub_feature_flags(allow_possible_spam: false)
            end

            it_behaves_like 'only checks for spam if a request is provided'

            it 'does not mark as spam' do
              subject

              expect(issue).not_to be_spam
            end

            it 'marks as needing reCAPTCHA' do
              subject

              expect(issue.needs_recaptcha?).to be_truthy
            end
          end

          context 'when allow_possible_spam feature flag is true' do
            it_behaves_like 'only checks for spam if a request is provided'

            it 'does not mark as needing reCAPTCHA' do
              subject

              expect(issue.needs_recaptcha).to be_falsey
            end
          end
        end

        context 'when spam verdict service allows creation' do
          before do
            allow(fake_verdict_service).to receive(:execute).and_return(ALLOW)
          end

          it 'does not create a spam log' do
            expect { subject }
              .not_to change { SpamLog.count }
          end
        end
      end
    end
  end
end
