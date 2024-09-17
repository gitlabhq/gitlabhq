# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitaly::Server do
  let(:server) { described_class.new('default') }

  describe '.all' do
    let(:storages) { Gitlab.config.repositories.storages }

    it 'includes all storages' do
      expect(storages.count).to eq(described_class.all.count)
      expect(storages.keys).to eq(described_class.all.map(&:storage))
    end
  end

  subject { described_class.all.first }

  it { is_expected.to respond_to(:server_version) }
  it { is_expected.to respond_to(:git_binary_version) }
  it { is_expected.to respond_to(:up_to_date?) }
  it { is_expected.to respond_to(:address) }
  it { is_expected.to respond_to(:replication_factor) }

  describe 'readable?' do
    context 'when the storage is readable' do
      it 'returns true' do
        expect(server).to be_readable
      end
    end

    context 'when the storage is not readable', :broken_storage do
      it 'returns false' do
        expect(server).not_to be_readable
      end
    end
  end

  describe 'writeable?' do
    context 'when the storage is writeable' do
      it 'returns true' do
        expect(server).to be_writeable
      end
    end

    context 'when the storage is not writeable', :broken_storage do
      it 'returns false' do
        expect(server).not_to be_writeable
      end
    end
  end

  describe "#filesystem_type" do
    subject { server.filesystem_type }

    it { is_expected.to be_present }
  end

  describe 'request memoization' do
    context 'when requesting multiple properties', :request_store do
      it 'uses memoization for the info request' do
        expect do
          subject.server_version
          subject.up_to_date?
        end.to change { Gitlab::GitalyClient.get_request_count }.by(1)
      end
    end
  end

  context "when examining disk statistics for a given server" do
    let(:disk_available) { 42 }
    let(:disk_used) { 42 }
    let(:storage_status) { double('storage_status') }

    before do
      allow(storage_status).to receive(:storage_name).and_return('default')
      allow(storage_status).to receive(:available).and_return(disk_available)
      allow(storage_status).to receive(:used).and_return(disk_used)
      response = double("response")
      allow(response).to receive(:storage_statuses).and_return([storage_status])
      allow_next_instance_of(Gitlab::GitalyClient::ServerService) do |instance|
        allow(instance).to receive(:disk_statistics).and_return(response)
      end
    end

    describe '#disk_available' do
      subject { server.disk_available }

      it { is_expected.to be_present }

      it "returns disk available for the storage of the instantiated server" do
        is_expected.to eq(disk_available)
      end
    end

    describe '#disk_used' do
      subject { server.disk_used }

      it { is_expected.to be_present }

      it "returns disk used for the storage of the instantiated server" do
        is_expected.to eq(disk_used)
      end
    end

    describe '#disk_stats' do
      subject { server.disk_stats }

      it { is_expected.to be_present }

      it "returns the storage of the instantiated server" do
        is_expected.to eq(storage_status)
      end
    end
  end

  describe '#expected_version?' do
    using RSpec::Parameterized::TableSyntax

    where(:expected_version, :server_version, :result) do
      '1.1.1'                                    | '1.1.1'               | true
      '1.1.2'                                    | '1.1.1'               | false
      '1.73.0'                                   | '1.73.0-18-gf756ebe2' | false
      '594c3ea3e0e5540e5915bd1c49713a0381459dd6' | '1.55.6-45-g594c3ea3' | true
      '594c3ea3e0e5540e5915bd1c49713a0381459dd6' | '1.55.6-46-gabc123ff' | false
      '594c3ea3e0e5540e5915bd1c49713a0381459dd6' | '1.55.6'              | false
    end

    with_them do
      it do
        allow(Gitlab::GitalyClient).to receive(:expected_server_version).and_return(expected_version)
        allow(server).to receive(:server_version).and_return(server_version)

        expect(server.expected_version?).to eq(result)
      end
    end
  end

  describe "#server_signature_public_key" do
    context 'when the server signature returns a public key' do
      let(:public_key) { 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFcykDaUT7x4oXyUCfgqJhfAXRbhtsLl4fi4142zrPCI' }

      before do
        allow_next_instance_of(Gitlab::GitalyClient::ServerService) do |instance|
          allow(instance).to receive_message_chain(:server_signature, :public_key).and_return(public_key)
        end
      end

      it 'returns a public key and no errors' do
        expect(server.server_signature_public_key).to eq(public_key)
        expect(server.server_signature_error?).to be(false)
      end
    end
  end

  describe "#server_signature_error?" do
    context 'when the server signature raises a GRPC error' do
      before do
        allow_next_instance_of(Gitlab::GitalyClient::ServerService) do |instance|
          allow(instance).to receive(:server_signature).and_raise(GRPC::Unavailable)
        end.once
      end

      it 'returns an error and no public_key' do
        expect(server.server_signature_public_key).to be_nil
        expect(server.server_signature_error?).to eq(true)
      end
    end
  end

  describe 'replication_factor' do
    context 'when examining for a given server' do
      let(:storage_status) { double('storage_status', storage_name: 'default') }

      before do
        response = double('response', storage_statuses: [storage_status])
        allow_next_instance_of(Gitlab::GitalyClient::ServerService) do |instance|
          allow(instance).to receive(:info).and_return(response)
        end
      end

      it do
        allow(storage_status).to receive(:replication_factor).and_return(2)
        expect(server.replication_factor).to eq(2)
      end
    end
  end
end
