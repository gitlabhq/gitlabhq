# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spam::SpamVerdictService, feature_category: :instance_resiliency do
  include_context 'includes Spam constants'

  let(:fake_ip) { '1.2.3.4' }
  let(:fake_user_agent) { 'fake-user-agent' }
  let(:fake_referer) { 'fake-http-referer' }
  let(:env) do
    { 'action_dispatch.remote_ip' => fake_ip,
      'HTTP_USER_AGENT' => fake_user_agent,
      'HTTP_REFERER' => fake_referer }
  end

  let(:verdict_value) { ::Spamcheck::SpamVerdict::Verdict::ALLOW }
  let(:verdict_score) { 0.01 }
  let(:verdict_evaluated) { true }

  let(:response) do
    response = ::Spamcheck::SpamVerdict.new
    response.verdict = verdict_value
    response.score = verdict_score
    response.evaluated = verdict_evaluated
    response
  end

  let(:spam_client_result) do
    Gitlab::Spamcheck::Result.new(response)
  end

  let(:check_for_spam) { true }
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, author: user) }
  let_it_be(:snippet) { create(:personal_snippet, :public, author: user) }

  let(:service) do
    described_class.new(user: user, target: target, options: {})
  end

  shared_examples 'execute spam verdict service' do
    subject(:execute) { service.execute }

    before do
      allow(service).to receive(:get_akismet_verdict).and_return(nil)
      allow(service).to receive(:get_spamcheck_verdict).and_return(nil)
    end

    context 'if all services return nil' do
      it 'renders ALLOW verdict' do
        is_expected.to eq ALLOW
      end
    end

    context 'if only one service returns a verdict' do
      context 'and it is supported' do
        before do
          allow(service).to receive(:get_akismet_verdict).and_return(DISALLOW)
        end

        it 'renders that verdict' do
          is_expected.to eq DISALLOW
        end
      end

      context 'and it is unexpected' do
        before do
          allow(service).to receive(:get_akismet_verdict).and_return("unexpected")
        end

        it 'allows' do
          is_expected.to eq ALLOW
        end
      end
    end

    context 'if more than one service returns a verdict' do
      context 'and they are supported' do
        before do
          allow(service).to receive(:get_akismet_verdict).and_return(DISALLOW)
          allow(service).to receive(:get_spamcheck_verdict).and_return(BLOCK_USER)
        end

        it 'renders the more restrictive verdict' do
          is_expected.to eq BLOCK_USER
        end
      end

      context 'and one is supported' do
        before do
          allow(service).to receive(:get_akismet_verdict).and_return('nonsense')
          allow(service).to receive(:get_spamcheck_verdict).and_return(BLOCK_USER)
        end

        it 'renders the more restrictive verdict' do
          is_expected.to eq BLOCK_USER
        end
      end

      context 'and none are supported' do
        before do
          allow(service).to receive(:get_akismet_verdict).and_return('nonsense')
          allow(service).to receive(:get_spamcheck_verdict).and_return('rubbish')
        end

        it 'renders the more restrictive verdict' do
          is_expected.to eq ALLOW
        end
      end
    end

    context 'if allow_possible_spam application setting is true' do
      before do
        stub_application_setting(allow_possible_spam: true)
      end

      context 'and a service returns a verdict that should be overridden' do
        before do
          allow(service).to receive(:get_spamcheck_verdict).and_return(BLOCK_USER)
        end

        it 'overrides and renders the override verdict' do
          is_expected.to eq OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM
        end
      end

      context 'and a service returns a verdict that does not need to be overridden' do
        before do
          allow(service).to receive(:get_spamcheck_verdict).and_return(ALLOW)
        end

        it 'does not override and renders the original verdict' do
          is_expected.to eq ALLOW
        end
      end
    end

    context 'if user is trusted to create possible spam' do
      before do
        user.custom_attributes.create!(key: 'trusted_by', value: 'does not matter')
      end

      context 'and a service returns a verdict that should be overridden' do
        before do
          allow(service).to receive(:get_spamcheck_verdict).and_return(BLOCK_USER)
        end

        it 'overrides and renders the override verdict' do
          is_expected.to eq OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM
        end
      end

      context 'and a service returns a verdict that does not need to be overridden' do
        before do
          allow(service).to receive(:get_spamcheck_verdict).and_return(ALLOW)
        end

        it 'does not override and renders the original verdict' do
          is_expected.to eq ALLOW
        end
      end
    end

    context 'records metrics' do
      let(:histogram) { instance_double(Prometheus::Client::Histogram) }

      using RSpec::Parameterized::TableSyntax

      where(:verdict, :label) do
        Spam::SpamConstants::ALLOW             |  'ALLOW'
        Spam::SpamConstants::CONDITIONAL_ALLOW |  'CONDITIONAL_ALLOW'
        Spam::SpamConstants::BLOCK_USER        |  'BLOCK'
        Spam::SpamConstants::DISALLOW          |  'DISALLOW'
        Spam::SpamConstants::NOOP              |  'NOOP'
      end

      with_them do
        before do
          allow(Gitlab::Metrics).to receive(:histogram).with(:gitlab_spamcheck_request_duration_seconds, anything).and_return(histogram)
          allow(service).to receive(:get_spamcheck_verdict).and_return(verdict)
        end

        it 'records duration with labels' do
          expect(histogram).to receive(:observe).with(a_hash_including(result: label), anything)
          execute
        end
      end
    end
  end

  shared_examples 'akismet verdict' do
    let(:target) { issue }

    subject(:get_akismet_verdict) { service.send(:get_akismet_verdict) }

    context 'if Akismet is enabled' do
      before do
        stub_application_setting(akismet_enabled: true)
        allow_next_instance_of(Spam::AkismetService) do |service|
          allow(service).to receive(:spam?).and_return(akismet_result)
        end
      end

      context 'if Akismet considers it spam' do
        let(:akismet_result) { true }

        context 'if reCAPTCHA is enabled' do
          before do
            stub_application_setting(recaptcha_enabled: true)
          end

          it 'returns conditionally allow verdict' do
            is_expected.to eq CONDITIONAL_ALLOW
          end
        end

        context 'if reCAPTCHA is not enabled' do
          before do
            stub_application_setting(recaptcha_enabled: false)
          end

          it 'renders disallow verdict' do
            is_expected.to eq DISALLOW
          end
        end
      end

      context 'if Akismet does not consider it spam' do
        let(:akismet_result) { false }

        it 'renders allow verdict' do
          is_expected.to eq ALLOW
        end
      end
    end

    context 'if Akismet is not enabled' do
      before do
        stub_application_setting(akismet_enabled: false)
      end

      it 'renders allow verdict' do
        is_expected.to eq ALLOW
      end
    end
  end

  shared_examples 'spamcheck verdict' do
    subject(:get_spamcheck_verdict) { service.send(:get_spamcheck_verdict) }

    context 'if a Spam Check endpoint enabled and set to a URL' do
      let(:spam_check_body) { {} }
      let(:endpoint_url) { "grpc://www.spamcheckurl.com/spam_check" }

      let(:spam_client) do
        Gitlab::Spamcheck::Client.new
      end

      before do
        stub_application_setting(spam_check_endpoint_enabled: true)
        stub_application_setting(spam_check_endpoint_url: endpoint_url)
      end

      context 'if the endpoint is accessible' do
        before do
          allow(service).to receive(:spamcheck_client).and_return(spam_client)
          allow(spam_client).to receive(:spam?).and_return(spam_client_result)
          allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return('cid')
        end

        context 'if the result is a NOOP verdict' do
          let(:verdict_evaluated) { false }
          let(:verdict_value) { ::Spamcheck::SpamVerdict::Verdict::NOOP }

          it 'returns the verdict' do
            expect(AntiAbuse::TrustScoreWorker).not_to receive(:perform_async)
            is_expected.to eq(NOOP)
          end
        end

        context 'the result is a valid verdict' do
          let(:verdict_score) { 0.05 }
          let(:verdict_value) { ::Spamcheck::SpamVerdict::Verdict::ALLOW }

          context 'the result was evaluated' do
            it 'returns the verdict and updates the spam score' do
              expect(AntiAbuse::TrustScoreWorker).to receive(:perform_async).once.with(user.id, :spamcheck, instance_of(Float), 'cid')
              is_expected.to eq(ALLOW)
            end
          end

          context 'the result was not evaluated' do
            let(:verdict_evaluated) { false }

            it 'returns the verdict and does not update the spam score' do
              expect(AntiAbuse::TrustScoreWorker).not_to receive(:perform_async)
              expect(subject).to eq(ALLOW)
            end
          end
        end

        context 'when recaptcha is enabled' do
          before do
            allow(Gitlab::Recaptcha).to receive(:enabled?).and_return(true)
          end

          using RSpec::Parameterized::TableSyntax

          where(:verdict_value, :expected, :verdict_score) do
            ::Spamcheck::SpamVerdict::Verdict::ALLOW              | ::Spam::SpamConstants::ALLOW              | 0.1
            ::Spamcheck::SpamVerdict::Verdict::CONDITIONAL_ALLOW  | ::Spam::SpamConstants::CONDITIONAL_ALLOW  | 0.5
            ::Spamcheck::SpamVerdict::Verdict::DISALLOW           | ::Spam::SpamConstants::DISALLOW           | 0.8
            ::Spamcheck::SpamVerdict::Verdict::BLOCK              | ::Spam::SpamConstants::BLOCK_USER         | 0.9
          end

          with_them do
            it "returns expected spam constant and updates the spam score" do
              expect(AntiAbuse::TrustScoreWorker).to receive(:perform_async).once.with(user.id, :spamcheck, instance_of(Float), 'cid')
              is_expected.to eq(expected)
            end
          end
        end

        context 'when recaptcha is disabled' do
          before do
            allow(Gitlab::Recaptcha).to receive(:enabled?).and_return(false)
          end

          using RSpec::Parameterized::TableSyntax

          where(:verdict_value, :expected) do
            ::Spamcheck::SpamVerdict::Verdict::ALLOW              | ::Spam::SpamConstants::ALLOW
            ::Spamcheck::SpamVerdict::Verdict::CONDITIONAL_ALLOW  | ::Spam::SpamConstants::CONDITIONAL_ALLOW
            ::Spamcheck::SpamVerdict::Verdict::DISALLOW           | ::Spam::SpamConstants::DISALLOW
            ::Spamcheck::SpamVerdict::Verdict::BLOCK              | ::Spam::SpamConstants::BLOCK_USER
          end

          with_them do
            it "returns expected spam constant" do
              is_expected.to eq(expected)
            end
          end
        end

        context 'the requested is aborted' do
          before do
            allow(spam_client).to receive(:spam?).and_raise(GRPC::Aborted)
          end

          it 'returns nil' do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
              an_instance_of(GRPC::Aborted), error: ::Spam::SpamConstants::ERROR_TYPE
            )
            is_expected.to be_nil
          end
        end

        context 'if the endpoint times out' do
          before do
            allow(spam_client).to receive(:spam?).and_raise(GRPC::DeadlineExceeded)
          end

          it 'returns nil' do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
              an_instance_of(GRPC::DeadlineExceeded), error: ::Spam::SpamConstants::ERROR_TYPE
            )
            is_expected.to be_nil
          end
        end
      end
    end

    context 'if a Spam Check endpoint is not set' do
      before do
        stub_application_setting(spam_check_endpoint_url: nil)
      end

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'if Spam Check endpoint is not enabled' do
      before do
        stub_application_setting(spam_check_endpoint_enabled: false)
      end

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#execute' do
    describe 'issue' do
      let(:target) { issue }

      context 'when issue is publicly visible' do
        before do
          allow(issue).to receive(:publicly_visible?).and_return(true)
        end

        it_behaves_like 'execute spam verdict service'
      end

      context 'when issue is not publicly visible' do
        before do
          allow(issue).to receive(:publicly_visible?).and_return(false)
          allow(service).to receive(:get_spamcheck_verdict).and_return(BLOCK_USER)
        end

        it 'overrides and renders the override verdict' do
          expect(service.execute).to eq OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM
        end
      end
    end

    describe 'snippet' do
      let(:target) { snippet }

      it_behaves_like 'execute spam verdict service'
    end
  end

  describe '#get_akismet_verdict' do
    describe 'issue' do
      let(:target) { issue }

      it_behaves_like 'akismet verdict'
    end

    describe 'snippet' do
      let(:target) { snippet }

      it_behaves_like 'akismet verdict'
    end
  end

  describe '#get_spamcheck_verdict' do
    describe 'issue' do
      let(:target) { issue }

      it_behaves_like 'spamcheck verdict'
    end

    describe 'snippet' do
      let(:target) { snippet }

      it_behaves_like 'spamcheck verdict'
    end
  end
end
