# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildRunnerSession, model: true do
  let!(:build) { create(:ci_build, :with_runner_session) }
  let(:url) { 'https://new.example.com' }

  subject { build.runner_session }

  it { is_expected.to belong_to(:build) }

  it { is_expected.to validate_presence_of(:build) }
  it { is_expected.to validate_presence_of(:url).with_message('must be a valid URL') }

  context 'nested attribute assignment' do
    it 'creates a new session' do
      simple_build = create(:ci_build)
      simple_build.runner_session_attributes = { url: url }
      simple_build.save!

      session = simple_build.reload.runner_session
      expect(session).to be_a(Ci::BuildRunnerSession)
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
    let(:service) { 'foo'}
    let(:port) { 80 }
    let(:path) { 'path' }
    let(:subprotocols) { nil }
    let(:specification) { subject.service_specification(service: service, port: port, path: path, subprotocols: subprotocols) }

    it 'returns service proxy url' do
      expect(specification[:url]).to eq "https://localhost/proxy/#{service}/#{port}/#{path}"
    end

    it 'returns default service proxy websocket subprotocol' do
      expect(specification[:subprotocols]).to eq %w[terminal.gitlab.com]
    end

    it 'returns empty hash if no url' do
      subject.url = ''

      expect(specification).to be_empty
    end

    context 'when port is not present' do
      let(:port) { nil }

      it 'uses the default port name' do
        expect(specification[:url]).to eq "https://localhost/proxy/#{service}/default_port/#{path}"
      end
    end

    context 'when the service is not present' do
      let(:service) { '' }

      it 'uses the service name "build" as default' do
        expect(specification[:url]).to eq "https://localhost/proxy/build/#{port}/#{path}"
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
end
