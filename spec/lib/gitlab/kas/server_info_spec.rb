# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kas::ServerInfo, feature_category: :deployment_management do
  subject(:server_info) { described_class.new }

  let(:git_ref) { '6a0281c68969d9ce8f36fdaf242b4f6e0503d940' }

  before do
    allow(Gitlab::Kas).to receive(:enabled?).and_return(true)

    # rubocop:disable RSpec/VerifiedDoubles -- Avoiding the false positive 'the Gitlab::Agent::ServerInfo::ServerInfo
    # class does not implement the instance method: version' when using instance_double(), which is only because
    # Ruby protobuf handle these message through method_missing instead of actually defining instance methods.
    response = double(Gitlab::Agent::ServerInfo::ServerInfo, version: '17.4.0-rc1', git_ref: git_ref)
    # rubocop:enable RSpec/VerifiedDoubles

    allow_next_instance_of(Gitlab::Kas::Client) do |instance|
      allow(instance).to receive(:get_server_info).and_return(response)
    end
  end

  shared_examples 'logs kas error' do
    it 'logs the error' do
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(error)

      subject
    end
  end

  context 'when kas client initialization fails' do
    let(:error) { Gitlab::Kas::Client::ConfigurationError.new('boom') }

    before do
      allow(Gitlab::Kas::Client).to receive(:new).and_raise(error)
    end

    it_behaves_like 'logs kas error'
  end

  context 'when kas rpc fail' do
    let(:error) { GRPC::Unavailable.new("failed to connect to all addresses") }

    before do
      allow_next_instance_of(Gitlab::Kas::Client) do |instance|
        allow(instance).to receive(:get_server_info).and_raise(error)
      end
    end

    it_behaves_like 'logs kas error'
  end

  describe '#version' do
    subject { server_info.version }

    it 'returns version' do
      is_expected.to eq('17.4.0-rc1')
    end
  end

  describe '#retrieved_server_info?' do
    it { is_expected.to be_retrieved_server_info }

    it 'returns false when server info is not retrieved' do
      allow_next_instance_of(Gitlab::Kas::Client) do |instance|
        allow(instance).to receive(:get_server_info).and_raise(Gitlab::Kas::Client::ConfigurationError)
      end

      is_expected.not_to be_retrieved_server_info
    end
  end

  describe '#version_info' do
    subject { server_info.version_info.to_s }

    context 'when git ref is a commit' do
      let(:git_ref) { '6a0281c68969d9ce8f36fdaf242b4f6e0503d940' }

      it { is_expected.to eq('17.4.0-rc1+6a0281c68969d9ce8f36fdaf242b4f6e0503d940') }
    end

    context 'when git ref is a tag' do
      let(:git_ref) { 'v17.4.0-rc1' }

      it { is_expected.to eq('17.4.0') }
    end

    context 'when git ref is empty' do
      let(:git_ref) { '' }

      it { is_expected.to eq('17.4.0') }
    end
  end
end
