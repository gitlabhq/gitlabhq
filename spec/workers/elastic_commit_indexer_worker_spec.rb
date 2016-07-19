require 'spec_helper'

describe ElasticCommitIndexerWorker do
  let(:project) { create(:project) }

  subject { described_class.new }

  describe '#perform' do
    it 'runs indexer' do
      expect_any_instance_of(Gitlab::Elastic::Indexer).to receive(:run)
      subject.perform(project.id, '0000', '0000')
    end
  end
end
