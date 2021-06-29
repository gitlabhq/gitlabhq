# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spam::SpamVerdictService do
  include_context 'includes Spam constants'

  let(:fake_ip) { '1.2.3.4' }
  let(:fake_user_agent) { 'fake-user-agent' }
  let(:fake_referer) { 'fake-http-referer' }
  let(:env) do
    { 'action_dispatch.remote_ip' => fake_ip,
      'HTTP_USER_AGENT' => fake_user_agent,
      'HTTP_REFERER' => fake_referer }
  end

  let(:check_for_spam) { true }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, author: user) }

  let(:service) do
    described_class.new(user: user, target: issue, options: {})
  end

  let(:attribs) do
    extra_attributes = { "monitorMode" => "false" }
    extra_attributes
  end

  describe '#execute' do
    subject { service.execute }

    before do
      allow(service).to receive(:akismet_verdict).and_return(nil)
      allow(service).to receive(:spamcheck_verdict).and_return([nil, attribs])
    end

    context 'if all services return nil' do
      it 'renders ALLOW verdict' do
        expect(subject).to eq ALLOW
      end
    end

    context 'if only one service returns a verdict' do
      context 'and it is supported' do
        before do
          allow(service).to receive(:akismet_verdict).and_return(DISALLOW)
        end

        it 'renders that verdict' do
          expect(subject).to eq DISALLOW
        end
      end

      context 'and it is unexpected' do
        before do
          allow(service).to receive(:akismet_verdict).and_return("unexpected")
        end

        it 'allows' do
          expect(subject).to eq ALLOW
        end
      end
    end

    context 'if more than one service returns a verdict' do
      context 'and they are supported' do
        before do
          allow(service).to receive(:akismet_verdict).and_return(DISALLOW)
          allow(service).to receive(:spamcheck_verdict).and_return([BLOCK_USER, attribs])
        end

        it 'renders the more restrictive verdict' do
          expect(subject).to eq BLOCK_USER
        end
      end

      context 'and one is supported' do
        before do
          allow(service).to receive(:akismet_verdict).and_return('nonsense')
          allow(service).to receive(:spamcheck_verdict).and_return([BLOCK_USER, attribs])
        end

        it 'renders the more restrictive verdict' do
          expect(subject).to eq BLOCK_USER
        end
      end

      context 'and none are supported' do
        before do
          allow(service).to receive(:akismet_verdict).and_return('nonsense')
          allow(service).to receive(:spamcheck_verdict).and_return(['rubbish', attribs])
        end

        it 'renders the more restrictive verdict' do
          expect(subject).to eq ALLOW
        end
      end

      context 'and attribs - monitorMode is true' do
        let(:attribs) do
          extra_attributes = { "monitorMode" => "true" }
          extra_attributes
        end

        before do
          allow(service).to receive(:akismet_verdict).and_return(DISALLOW)
          allow(service).to receive(:spamcheck_verdict).and_return([BLOCK_USER, attribs])
        end

        it 'renders the more restrictive verdict' do
          expect(subject).to eq(DISALLOW)
        end
      end
    end

    context 'records metrics' do
      let(:histogram) { instance_double(Prometheus::Client::Histogram) }

      using RSpec::Parameterized::TableSyntax

      where(:verdict, :error, :label) do
        Spam::SpamConstants::ALLOW             |  false |  'ALLOW'
        Spam::SpamConstants::ALLOW             |  true  |  'ERROR'
        Spam::SpamConstants::CONDITIONAL_ALLOW |  false |  'CONDITIONAL_ALLOW'
        Spam::SpamConstants::BLOCK_USER        |  false |  'BLOCK'
        Spam::SpamConstants::DISALLOW          |  false |  'DISALLOW'
        Spam::SpamConstants::NOOP              |  false |  'NOOP'
      end

      with_them do
        before do
          allow(Gitlab::Metrics).to receive(:histogram).with(:gitlab_spamcheck_request_duration_seconds, anything).and_return(histogram)
          allow(service).to receive(:spamcheck_verdict).and_return([verdict, attribs, error])
        end

        it 'records duration with labels' do
          expect(histogram).to receive(:observe).with(a_hash_including(result: label), anything)
          subject
        end
      end
    end
  end

  describe '#akismet_verdict' do
    subject { service.send(:akismet_verdict) }

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
            expect(subject).to eq CONDITIONAL_ALLOW
          end
        end

        context 'if reCAPTCHA is not enabled' do
          before do
            stub_application_setting(recaptcha_enabled: false)
          end

          it 'renders disallow verdict' do
            expect(subject).to eq DISALLOW
          end
        end
      end

      context 'if Akismet does not consider it spam' do
        let(:akismet_result) { false }

        it 'renders allow verdict' do
          expect(subject).to eq ALLOW
        end
      end
    end

    context 'if Akismet is not enabled' do
      before do
        stub_application_setting(akismet_enabled: false)
      end

      it 'renders allow verdict' do
        expect(subject).to eq ALLOW
      end
    end
  end

  describe '#spamcheck_verdict' do
    subject { service.send(:spamcheck_verdict) }

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
        let(:error) { '' }
        let(:verdict) { nil }

        let(:attribs) do
          extra_attributes = { "monitorMode" => "false" }
          extra_attributes
        end

        before do
          allow(service).to receive(:spamcheck_client).and_return(spam_client)
          allow(spam_client).to receive(:issue_spam?).and_return([verdict, attribs, error])
        end

        context 'if the result is a NOOP verdict' do
          let(:verdict) { NOOP }

          it 'returns the verdict' do
            expect(subject).to eq([NOOP, attribs])
          end
        end

        context 'if attribs - monitorMode is true' do
          let(:attribs) do
            extra_attributes = { "monitorMode" => "true" }
            extra_attributes
          end

          let(:verdict) { ALLOW }

          it 'returns the verdict' do
            expect(subject).to eq([ALLOW, attribs])
          end
        end

        context 'the result is a valid verdict' do
          let(:verdict) { ALLOW }

          it 'returns the verdict' do
            expect(subject).to eq([ALLOW, attribs])
          end
        end

        context 'when recaptcha is enabled' do
          before do
            allow(Gitlab::Recaptcha).to receive(:enabled?).and_return(true)
          end

          using RSpec::Parameterized::TableSyntax

          # rubocop: disable Lint/BinaryOperatorWithIdenticalOperands
          where(:verdict_value, :expected) do
            ::Spam::SpamConstants::ALLOW               | ::Spam::SpamConstants::ALLOW
            ::Spam::SpamConstants::CONDITIONAL_ALLOW   | ::Spam::SpamConstants::CONDITIONAL_ALLOW
            ::Spam::SpamConstants::DISALLOW            | ::Spam::SpamConstants::CONDITIONAL_ALLOW
            ::Spam::SpamConstants::BLOCK_USER          | ::Spam::SpamConstants::CONDITIONAL_ALLOW
          end
          # rubocop: enable Lint/BinaryOperatorWithIdenticalOperands

          with_them do
            let(:verdict) { verdict_value }

            it "returns expected spam constant" do
              expect(subject).to eq([expected, attribs])
            end
          end
        end

        context 'when recaptcha is disabled' do
          before do
            allow(Gitlab::Recaptcha).to receive(:enabled?).and_return(false)
          end

          [::Spam::SpamConstants::ALLOW,
           ::Spam::SpamConstants::CONDITIONAL_ALLOW,
           ::Spam::SpamConstants::DISALLOW,
           ::Spam::SpamConstants::BLOCK_USER].each do |verdict_value|
            let(:verdict) { verdict_value }
            let(:expected) { [verdict_value, attribs] }

            it "returns expected spam constant" do
              expect(subject).to eq(expected)
            end
          end
        end

        context 'the verdict is an unexpected value' do
          let(:verdict) { :this_is_fine }

          it 'returns the string' do
            expect(subject).to eq([verdict, attribs])
          end
        end

        context 'the verdict is an empty string' do
          let(:verdict) { '' }

          it 'returns nil' do
            expect(subject).to eq([verdict, attribs])
          end
        end

        context 'the verdict is nil' do
          let(:verdict) { nil }

          it 'returns nil' do
            expect(subject).to eq([nil, attribs])
          end
        end

        context 'there is an error' do
          let(:error) { "Sorry Dave, I can't do that" }

          it 'returns nil' do
            expect(subject).to eq([nil, attribs])
          end
        end

        context 'the requested is aborted' do
          let(:attribs) { nil }

          before do
            allow(spam_client).to receive(:issue_spam?).and_raise(GRPC::Aborted)
          end

          it 'returns nil' do
            expect(subject).to eq([ALLOW, attribs, true])
          end
        end

        context 'the confused API endpoint returns both an error and a verdict' do
          let(:verdict) { 'disallow' }
          let(:error) { 'oh noes!' }

          it 'renders the verdict' do
            expect(subject).to eq [DISALLOW, attribs]
          end
        end
      end

      context 'if the endpoint times out' do
        let(:attribs) { nil }

        before do
          allow(spam_client).to receive(:issue_spam?).and_raise(GRPC::DeadlineExceeded)
        end

        it 'returns nil' do
          expect(subject).to eq([ALLOW, attribs, true])
        end
      end
    end

    context 'if a Spam Check endpoint is not set' do
      before do
        stub_application_setting(spam_check_endpoint_url: nil)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'if Spam Check endpoint is not enabled' do
      before do
        stub_application_setting(spam_check_endpoint_enabled: false)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
