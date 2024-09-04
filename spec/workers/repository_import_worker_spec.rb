# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryImportWorker, feature_category: :importers do
  describe '#perform' do
    let(:project) { build_stubbed(:project, :import_scheduled, import_state: import_state, import_url: 'url') }
    let(:import_state) { create(:import_state, status: :scheduled) }
    let(:jid) { '12345678' }

    before do
      allow(subject).to receive(:jid).and_return(jid)
      allow(Project).to receive(:find_by_id).with(project.id).and_return(project)
      allow(project).to receive(:after_import)
      allow(import_state).to receive(:start).and_return(true)
    end

    context 'when project not found (deleted)' do
      before do
        allow(Project).to receive(:find_by_id).with(project.id).and_return(nil)
      end

      it 'does not raise any exception' do
        expect(Projects::ImportService).not_to receive(:new)

        expect { subject.perform(project.id) }.not_to raise_error
      end
    end

    context 'when import_state is scheduled' do
      it 'imports the project successfully' do
        expect_next_instance_of(Projects::ImportService) do |instance|
          expect(instance).to receive(:execute).and_return({ status: :ok })
        end

        subject.perform(project.id)

        expect(project).to have_received(:after_import)
        expect(import_state).to have_received(:start)
      end
    end

    context 'when worker was reset without cleanup (import_state is started)' do
      let(:import_state) { create(:import_state, :started, jid: jid) }

      it 'imports the project successfully' do
        expect_next_instance_of(Projects::ImportService) do |instance|
          expect(instance).to receive(:execute).and_return({ status: :ok })
        end

        subject.perform(project.id)

        expect(project).to have_received(:after_import)
        expect(import_state).not_to have_received(:start)
      end
    end

    context 'when using an asynchronous importer' do
      it 'does not mark the import process as finished' do
        expect_next_instance_of(Projects::ImportService) do |instance|
          expect(instance).to receive(:execute).and_return({ status: :ok })
          expect(instance).to receive(:async?).and_return(true)
        end

        subject.perform(project.id)

        expect(project).not_to have_received(:after_import)
      end
    end

    context 'when the import has failed' do
      let(:error) { "https://user:pass@test.com/root/repoC.git/ not found" }

      before do
        allow(import_state).to receive(:mark_as_failed)
      end

      it 'marks import_state as failed' do
        expect_next_instance_of(Projects::ImportService) do |instance|
          expect(project).to receive(:reset_counters_and_iids)
          expect(instance).to receive(:execute).and_return({ status: :error, message: error })
        end

        subject.perform(project.id)

        expect(import_state).to have_received(:mark_as_failed).with(error)
        expect(project).not_to have_received(:after_import)
      end
    end
  end
end
