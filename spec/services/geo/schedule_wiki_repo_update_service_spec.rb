require 'spec_helper'

describe Geo::ScheduleWikiRepoUpdateService do
  describe '#execute' do
    let(:group) { create(:group) }
    let(:project_1) { create(:project) }
    let(:project_2) { create(:project, group: group) }

    let(:projects) do
      [
        { 'id' => project_1.id, 'clone_url' => 'git@example.com:mike/diaspora.git' },
        { 'id' => project_2.id, 'clone_url' => 'git@example.com:asd/vim.git' }
      ]
    end

    subject { described_class.new(projects) }

    it "enqueues a batch of IDs of wiki's projects to have their wiki repositories updated" do
      expect(GeoWikiRepositoryUpdateWorker).to receive(:perform_async)
        .once.with(project_1.id, 'git@example.com:mike/diaspora.git').and_return(spy)
      expect(GeoWikiRepositoryUpdateWorker).to receive(:perform_async)
        .once.with(project_2.id, 'git@example.com:asd/vim.git').and_return(spy)

      subject.execute
    end

    context 'when node has namespace restrictions' do
      it "does not enqueue IDs of wiki's projects that do not belong to selected namespaces to replicate" do
        create(:geo_node, :current, namespaces: [group])

        expect(GeoWikiRepositoryUpdateWorker).not_to receive(:perform_async)
          .with(project_1.id, 'git@example.com:mike/diaspora.git')
        expect(GeoWikiRepositoryUpdateWorker).to receive(:perform_async)
          .once.with(project_2.id, 'git@example.com:asd/vim.git').and_return(spy)

        subject.execute
      end
    end
  end
end
