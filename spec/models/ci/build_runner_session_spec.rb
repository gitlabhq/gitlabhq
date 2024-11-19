# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildRunnerSession, :model, feature_category: :continuous_integration do
  let!(:build) { create(:ci_build, :with_runner_session) }
  let(:url) { 'https://new.example.com' }

  subject { build.runner_session }

  it { is_expected.to belong_to(:build) }

  it { is_expected.to validate_presence_of(:build) }
  it { is_expected.to validate_presence_of(:url).with_message('must be a valid URL') }

  context 'url validation of local web hook address' do
    let(:url) { 'https://127.0.0.1:7777' }

    subject(:build_with_local_runner_session_url) do
      create(:ci_build).tap { |b| b.update!(runner_session_attributes: { url: url }) }
    end

    context 'with allow_local_requests_from_web_hooks_and_services? stubbed' do
      before do
        allow(ApplicationSetting).to receive(:current).and_return(ApplicationSetting.new)
        stub_application_setting(allow_local_requests_from_web_hooks_and_services: allow_local_requests)
      end

      context 'as returning true' do
        let(:allow_local_requests) { true }

        it 'creates a new session', :aggregate_failures do
          session = build_with_local_runner_session_url.reload.runner_session

          expect(session.errors).to be_empty
          expect(session).to be_a(described_class)
          expect(session.url).to eq(url)
        end
      end

      context 'as returning false' do
        let(:allow_local_requests) { false }

        it 'does not create a new session' do
          expect { build_with_local_runner_session_url }.to raise_error(ActiveRecord::RecordInvalid) do |err|
            expect(err.record.errors.full_messages).to include(
              'Runner session url is blocked: Requests to localhost are not allowed'
            )
          end
        end
      end
    end
  end

  context 'nested attribute assignment' do
    it 'creates a new session' do
      simple_build = create(:ci_build)
      simple_build.runner_session_attributes = { url: url }
      simple_build.save!

      session = simple_build.reload.runner_session
      expect(session).to be_a(described_class)
      expect(session.url).to eq(url)
    end

    it 'updates session with new attributes' do
      build.runner_session_attributes = { url: url }
      build.save!

      expect(build.reload.runner_session.url).to eq(url)
    end
  end

  describe '#terminal_specification' do
    let(:specification) { subject.terminal_specification }

    it 'returns terminal.gitlab.com protocol' do
      expect(specification[:subprotocols]).to eq ['terminal.gitlab.com']
    end

    it 'returns a wss url' do
      expect(specification[:url]).to start_with('wss://')
    end

    it 'returns empty hash if no url' do
      subject.url = ''

      expect(specification).to be_empty
    end

    it 'returns url with appended query if url has query' do
      subject.url = 'https://new.example.com:7777/some_path?dummy='

      expect(specification[:url]).to eq('wss://new.example.com:7777/some_path/exec?dummy=')
    end

    context 'when url is present' do
      it 'returns ca_pem nil if empty certificate' do
        subject.certificate = ''

        expect(specification[:ca_pem]).to be_nil
      end

      it 'adds Authorization header if authorization is present' do
        subject.authorization = 'whatever'

        expect(specification[:headers]).to include(Authorization: ['whatever'])
      end
    end
  end

  describe '#service_specification' do
    let(:service) { 'foo' }
    let(:port) { 80 }
    let(:path) { 'path' }
    let(:subprotocols) { nil }
    let(:specification) { subject.service_specification(service: service, port: port, path: path, subprotocols: subprotocols) }

    it 'returns service proxy url' do
      expect(specification[:url]).to eq "https://gitlab.example.com/proxy/#{service}/#{port}/#{path}"
    end

    it 'returns default service proxy websocket subprotocol' do
      expect(specification[:subprotocols]).to eq %w[terminal.gitlab.com]
    end

    it 'returns empty hash if no url' do
      subject.url = ''

      expect(specification).to be_empty
    end

    it 'returns url with appended query if url has query' do
      subject.url = 'https://new.example.com:7777/some_path?dummy='

      expect(specification[:url]).to eq("https://new.example.com:7777/some_path/proxy/#{service}/#{port}/#{path}?dummy=")
    end

    context 'when port is not present' do
      let(:port) { nil }

      it 'uses the default port name' do
        expect(specification[:url]).to eq "https://gitlab.example.com/proxy/#{service}/default_port/#{path}"
      end
    end

    context 'when the service is not present' do
      let(:service) { '' }

      it 'uses the service name "build" as default' do
        expect(specification[:url]).to eq "https://gitlab.example.com/proxy/build/#{port}/#{path}"
      end
    end

    context 'when url is present' do
      it 'returns ca_pem nil if empty certificate' do
        subject.certificate = ''

        expect(specification[:ca_pem]).to be_nil
      end

      it 'adds Authorization header if authorization is present' do
        subject.authorization = 'foobar'

        expect(specification[:headers]).to include(Authorization: ['foobar'])
      end
    end

    context 'when subprotocol is present' do
      let(:subprotocols) { 'foobar' }

      it 'returns the new subprotocol' do
        expect(specification[:subprotocols]).to eq [subprotocols]
      end
    end
  end

  describe 'partitioning' do
    include Ci::PartitioningHelpers

    let(:new_pipeline) { create(:ci_pipeline) }
    let(:new_build) { create(:ci_build, pipeline: new_pipeline) }
    let(:build_runner_session) { create(:ci_build_runner_session, build: new_build) }

    before do
      stub_current_partition_id(ci_testing_partition_id)
    end

    it 'assigns the same partition id as the one that build has' do
      expect(build_runner_session.partition_id).to eq(ci_testing_partition_id)
    end
  end
end
