require 'spec_helper'

describe ElasticCommitIndexerWorker do
  let(:project) { create(:project) }

  subject { described_class.new }

  describe '#perform' do
    it 'runs indexer' do
      expect_any_instance_of(Gitlab::Elastic::Indexer).to receive(:run)
      subject.perform(project.id, '0000', '0000')
    end

    it 'does not run indexer when project is empty' do
      empty_project = create :empty_project

      expect_any_instance_of(Gitlab::Elastic::Indexer).not_to receive(:run)

      subject.perform(empty_project.id, '0000', '0000')
    end

    it 'returns true if repository has unborn head' do
      project = create :project
      rugged = double('rugged')
      expect(rugged).to receive(:head_unborn?).and_return(true)
      expect_any_instance_of(Repository).to receive(:rugged).and_return(rugged)

      expect(subject.perform(project.id)).to be_truthy
    end
  end
end
