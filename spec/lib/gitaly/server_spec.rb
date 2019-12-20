# frozen_string_literal: true

require 'spec_helper'

describe Gitaly::Server do
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
end
