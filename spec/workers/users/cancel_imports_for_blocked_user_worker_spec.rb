# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::CancelImportsForBlockedUserWorker, feature_category: :importers do
  let_it_be_with_reload(:user) { create(:user, :blocked) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:scheduled_project) { create(:project, :import_scheduled, import_type: 'github', creator: user) }
  let_it_be(:started_project) { create(:project, :import_started, creator: user) }
  let_it_be(:finished_project) { create(:project, :import_finished, creator: user) }
  let_it_be(:mirror_project) { create(:project, :import_started, mirror: true, creator: user) }
  let_it_be(:other_user_project) { create(:project, :import_started, creator: other_user) }

  let_it_be(:created_bulk_import) { create(:bulk_import, :created, user: user) }
  let_it_be(:started_bulk_import) { create(:bulk_import, :started, user: user) }
  let_it_be(:finished_bulk_import) { create(:bulk_import, :finished, user: user) }
  let_it_be(:other_user_bulk_import) { create(:bulk_import, :started, user: other_user) }

  subject(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [user.id] }

    it 'cancels in-flight imports created by the user' do
      perform_idempotent_work

      expect(scheduled_project.import_state.reload).to be_canceled
      expect(started_project.import_state.reload).to be_canceled
      expect(created_bulk_import.reload).to be_canceled
      expect(started_bulk_import.reload).to be_canceled
    end

    it 'leaves completed imports, pull mirrors and other users imports untouched' do
      perform_idempotent_work

      expect(finished_project.import_state.reload).to be_finished
      expect(mirror_project.import_state.reload.status).to eq('started')
      expect(other_user_project.import_state.reload.status).to eq('started')
      expect(finished_bulk_import.reload).to be_finished
      expect(other_user_bulk_import.reload).to be_started
    end
  end

  describe '#perform' do
    it 'logs the number of canceled imports' do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:canceled_project_imports, 2)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:canceled_bulk_imports, 2)

      worker.perform(user.id)
    end

    context 'when the user does not exist' do
      it 'does nothing' do
        expect { worker.perform(non_existing_record_id) }
          .not_to change { started_project.import_state.reload.status }
      end
    end

    context 'when the user is active' do
      it 'does nothing' do
        expect { worker.perform(other_user.id) }
          .not_to change { other_user_project.import_state.reload.status }
      end
    end

    context 'when a project import cancellation fails' do
      it 'cancels the remaining imports and logs the failure' do
        allow_next_found_instance_of(ProjectImportState) do |import_state|
          allow(import_state).to receive(:cancel).and_wrap_original do |original|
            raise StandardError, 'race' if import_state.project_id == scheduled_project.id

            original.call
          end
        end

        expect(::Import::Framework::Logger).to receive(:error).with(
          hash_including(message: 'Failed to cancel import for blocked user', Labkit::Fields::ERROR_MESSAGE => 'race',
            import_type: 'github')
        )

        worker.perform(user.id)

        expect(scheduled_project.import_state.reload).to be_scheduled
        expect(started_project.import_state.reload).to be_canceled
        expect(created_bulk_import.reload).to be_canceled
        expect(started_bulk_import.reload).to be_canceled
      end
    end

    context 'when a bulk import cancellation fails' do
      it 'cancels the remaining bulk imports, logs the failure and does not count it' do
        allow_next_found_instance_of(BulkImport) do |bulk_import|
          allow(bulk_import).to receive(:cancel).and_wrap_original do |original|
            raise StandardError, 'race' if bulk_import.id == created_bulk_import.id

            original.call
          end
        end

        expect(::Import::Framework::Logger).to receive(:error).with(
          hash_including(message: 'Failed to cancel import for blocked user', Labkit::Fields::ERROR_MESSAGE => 'race',
            bulk_import_id: created_bulk_import.id)
        )
        expect(worker).to receive(:log_extra_metadata_on_done).with(:canceled_project_imports, 2)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:canceled_bulk_imports, 1)

        worker.perform(user.id)

        expect(created_bulk_import.reload).to be_created
        expect(started_bulk_import.reload).to be_canceled
      end
    end
  end
end
