require 'spec_helper'

describe Gitlab::Geo::LogCursor::Daemon do
  describe '#run!' do
    it 'traps signals' do
      allow(subject).to receive(:exit?) { true }
      expect(subject).to receive(:trap_signals)

      subject.run!
    end

    context 'when the command-line defines full_scan: true' do
      subject { described_class.new(full_scan: true) }

      it 'executes a full-scan' do
        allow(subject).to receive(:exit?) { true }

        expect(subject).to receive(:full_scan!)

        subject.run!
      end
    end

    context 'when processing a repository updated event' do
      let(:event_log) { create(:geo_event_log) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let(:repository_updated_event) { event_log.repository_updated_event }

      before do
        allow(subject).to receive(:exit?).and_return(false, true)
      end

      it 'creates a new project registry if it does not exist' do
        expect { subject.run! }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'sets resync_repository to true if event source is repository' do
        repository_updated_event.update_attribute(:source, Geo::RepositoryUpdatedEvent::REPOSITORY)
        registry = create(:geo_project_registry, :synced, project: repository_updated_event.project)

        subject.run!

        expect(registry.reload.resync_repository).to be true
      end

      it 'sets resync_wiki to true if event source is wiki' do
        repository_updated_event.update_attribute(:source, Geo::RepositoryUpdatedEvent::WIKI)
        registry = create(:geo_project_registry, :synced, project: repository_updated_event.project)

        subject.run!

        expect(registry.reload.resync_wiki).to be true
      end
    end
  end
end
