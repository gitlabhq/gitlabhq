require 'spec_helper'

describe Gitaly::Server do
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
end
