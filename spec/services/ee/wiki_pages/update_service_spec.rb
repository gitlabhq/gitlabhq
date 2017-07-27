require 'spec_helper'

describe WikiPages::UpdateService do
  let(:project) { create(:empty_project) }
  let(:user)    { create(:user) }
  let(:page)    { create(:wiki_page) }

  let(:opts) do
    {
      content: 'New content for wiki page',
      format: 'markdown',
      message: 'New wiki message'
    }
  end

  subject(:service) { described_class.new(project, user, opts) }

  before do
    project.add_master(user)
  end

  describe '#execute' do
    context 'when running on a Geo primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'triggers Geo::RepositoryUpdatedEventStore when Geo is enabled' do
        expect(Geo::RepositoryUpdatedEventStore).to receive(:new).with(instance_of(Project), source: Geo::RepositoryUpdatedEvent::WIKI).and_call_original
        expect_any_instance_of(Geo::RepositoryUpdatedEventStore).to receive(:create)

        service.execute(page)
      end

      it 'triggers wiki update on secondary nodes' do
        expect(Gitlab::Geo).to receive(:notify_wiki_update).with(instance_of(Project))

        service.execute(page)
      end
    end
  end
end
