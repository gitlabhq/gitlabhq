require 'spec_helper'

describe BuildkiteService, :use_clean_rails_memory_store_caching do
  include ReactiveCachingHelpers

  let(:project) { create(:project) }

  subject(:service) do
    described_class.create(
      project: project,
      properties: {
        service_hook: true,
        project_url: 'https://buildkite.com/account-name/example-project',
        token: 'secret-sauce-webhook-token:secret-sauce-status-token'
      }
    )
  end

  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to validate_presence_of(:token) }
      it_behaves_like 'issue tracker service URL attribute', :project_url
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.not_to validate_presence_of(:token) }
    end
  end

  describe 'commits methods' do
    before do
      allow(project).to receive(:default_branch).and_return('default-brancho')
    end

    describe '#webhook_url' do
      it 'returns the webhook url' do
        expect(service.webhook_url).to eq(
          'https://webhook.buildkite.com/deliver/secret-sauce-webhook-token'
        )
      end
    end

    describe '#commit_status_path' do
      it 'returns the correct status page' do
        expect(service.commit_status_path('2ab7834c')).to eq(
          'https://gitlab.buildkite.com/status/secret-sauce-status-token.json?commit=2ab7834c'
        )
      end
    end

    describe '#build_page' do
      it 'returns the correct build page' do
        expect(service.build_page('2ab7834c', nil)).to eq(
          'https://buildkite.com/account-name/example-project/builds?commit=2ab7834c'
        )
      end
    end

    describe '#commit_status' do
      it 'returns the contents of the reactive cache' do
        stub_reactive_cache(service, { commit_status: 'foo' }, 'sha', 'ref')

        expect(service.commit_status('sha', 'ref')).to eq('foo')
      end
    end

    describe '#calculate_reactive_cache' do
      context '#commit_status' do
        subject { service.calculate_reactive_cache('123', 'unused')[:commit_status] }

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
      end
    end
  end

  def stub_request(status: 200, body: nil)
    body ||= %q({"status":"success"})
    buildkite_full_url = 'https://gitlab.buildkite.com/status/secret-sauce-status-token.json?commit=123'

    WebMock.stub_request(:get, buildkite_full_url).to_return(
      status: status,
      headers: { 'Content-Type' => 'application/json' },
      body: body
    )
  end
end
