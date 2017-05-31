require 'spec_helper'

describe WikiPages::DestroyService, services: true do
  let(:project) { create(:empty_project) }
  let(:user)    { create(:user) }
  let(:page)    { create(:wiki_page) }

  subject(:service) { described_class.new(project, user) }

  before do
    project.add_master(user)
  end

  describe '#execute' do
    it 'executes webhooks' do
      expect(service).to receive(:execute_hooks).once.with(instance_of(WikiPage), 'delete')

      service.execute(page)
    end

    context 'when running on a Geo primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'triggers Geo::PushEventStore when Geo is enabled' do
        expect(Geo::PushEventStore).to receive(:new).with(instance_of(Project), source: Geo::PushEvent::WIKI).and_call_original
        expect_any_instance_of(Geo::PushEventStore).to receive(:create)

        service.execute(page)
      end

      it 'triggers wiki update on secondary nodes' do
        expect(Gitlab::Geo).to receive(:notify_wiki_update).with(instance_of(Project))

        service.execute(page)
      end
    end
  end
end
