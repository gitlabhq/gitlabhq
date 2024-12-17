# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Buildkite, :use_clean_rails_memory_store_caching, feature_category: :integrations do
  include ReactiveCachingHelpers
  include StubRequests

  let_it_be(:project) { create(:project) }

  subject(:integration) do
    described_class.create!(
      project: project,
      properties: {
        project_url: 'https://buildkite.com/organization-name/example-pipeline',
        token: 'secret-sauce-webhook-token:secret-sauce-status-token'
      }
    )
  end

  it_behaves_like Integrations::Base::Ci

  it_behaves_like Integrations::ResetSecretFields

  it_behaves_like Integrations::HasWebHook do
    let(:hook_url) { 'https://webhook.buildkite.com/deliver/{webhook_token}' }
  end

  it_behaves_like Integrations::HasAvatar

  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to validate_presence_of(:token) }

      it_behaves_like 'issue tracker integration URL attribute', :project_url
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.not_to validate_presence_of(:token) }
    end
  end

  describe '.supported_events' do
    it 'supports push, merge_request, and tag_push events' do
      expect(integration.supported_events).to eq %w[push merge_request tag_push]
    end
  end

  describe 'commits methods' do
    before do
      allow(project).to receive(:default_branch).and_return('default-brancho')
    end

    it 'always activates SSL verification after saved' do
      integration.create_service_hook(enable_ssl_verification: false)

      integration.enable_ssl_verification = false
      integration.active = true

      expect { integration.save! }
        .to change { integration.service_hook.enable_ssl_verification }.from(false).to(true)
    end

    describe '#hook_url' do
      it 'returns the webhook url' do
        expect(integration.hook_url).to eq('https://webhook.buildkite.com/deliver/{webhook_token}')
      end
    end

    describe '#commit_status_path' do
      it 'returns the correct status page' do
        expect(integration.commit_status_path('2ab7834c')).to eq(
          'https://gitlab.buildkite.com/status/secret-sauce-status-token.json?commit=2ab7834c'
        )
      end
    end

    describe '#build_page' do
      it 'returns the correct build page' do
        expect(integration.build_page('2ab7834c', nil)).to eq(
          'https://buildkite.com/organization-name/example-pipeline/builds?commit=2ab7834c'
        )
      end
    end

    describe '#commit_status' do
      it 'returns the contents of the reactive cache' do
        stub_reactive_cache(integration, { commit_status: 'foo' }, 'sha', 'ref')

        expect(integration.commit_status('sha', 'ref')).to eq('foo')
      end
    end

    describe '#calculate_reactive_cache' do
      describe '#commit_status' do
        let(:buildkite_full_url) { 'https://gitlab.buildkite.com/status/secret-sauce-status-token.json?commit=123' }

        subject { integration.calculate_reactive_cache('123', 'unused')[:commit_status] }

        it 'sets commit status to :error when status is 500' do
          stub_request(status: 500)

          is_expected.to eq(:error)
        end

        it 'sets commit status to :error when status is 404' do
          stub_request(status: 404)

          is_expected.to eq(:error)
        end

        it 'passes through build status untouched when status is 200' do
          stub_request(body: %q({"status":"Great Success"}))

          is_expected.to eq('Great Success')
        end

        Gitlab::HTTP::HTTP_ERRORS.each do |http_error|
          it "sets commit status to :error with a #{http_error.name} error" do
            WebMock.stub_request(:get, buildkite_full_url)
              .to_raise(http_error)

            expect(Gitlab::ErrorTracking)
              .to receive(:log_exception)
              .with(instance_of(http_error), { project_id: project.id })

            is_expected.to eq(:error)
          end
        end
      end
    end
  end

  def stub_request(status: 200, body: nil)
    body ||= %q({"status":"success"})

    stub_full_request(buildkite_full_url).to_return(
      status: status,
      headers: { 'Content-Type' => 'application/json' },
      body: body
    )
  end
end
