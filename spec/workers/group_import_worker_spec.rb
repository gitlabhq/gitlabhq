# frozen_string_literal: true

require 'spec_helper'

describe GroupImportWorker do
  let!(:user) { create(:user) }
  let!(:group) { create(:group) }

  subject { described_class.new }

  before do
    allow_next_instance_of(described_class) do |job|
      allow(job).to receive(:jid).and_return(SecureRandom.hex(8))
    end
  end

  describe '#perform' do
    context 'when it succeeds' do
      before do
        expect_next_instance_of(::Groups::ImportExport::ImportService) do |service|
          expect(service).to receive(:execute)
        end
      end

      it 'calls the ImportService' do
        subject.perform(user.id, group.id)
      end

      context 'when the import state does not exist' do
        it 'creates group import' do
          expect(group.import_state).to be_nil

          subject.perform(user.id, group.id)
          import_state = group.reload.import_state

          expect(import_state).to be_instance_of(GroupImportState)
          expect(import_state.status_name).to eq(:finished)
          expect(import_state.jid).not_to be_empty
        end

        it 'sets the group import status to started' do
          expect_next_instance_of(GroupImportState) do |import|
            expect(import).to receive(:start!).and_call_original
          end

          subject.perform(user.id, group.id)
        end

        it 'sets the group import status to finished' do
          expect_next_instance_of(GroupImportState) do |import|
            expect(import).to receive(:finish!).and_call_original
          end

          subject.perform(user.id, group.id)
        end
      end

      context 'when the import state already exists' do
        it 'updates the existing state' do
          existing_state = create(:group_import_state, group: group)

          expect { subject.perform(user.id, group.id) }
            .not_to change { GroupImportState.count }

          expect(existing_state.reload).to be_finished
        end
      end
    end

    context 'when it fails' do
      it 'raises an exception when params are invalid' do
        expect_any_instance_of(::Groups::ImportExport::ImportService).not_to receive(:execute)

        expect { subject.perform(non_existing_record_id, group.id) }.to raise_exception(ActiveRecord::RecordNotFound)
        expect { subject.perform(user.id, non_existing_record_id) }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      context 'import state' do
        before do
          expect_next_instance_of(::Groups::ImportExport::ImportService) do |service|
            expect(service).to receive(:execute).and_raise(Gitlab::ImportExport::Error)
          end
        end

        it 'sets the group import status to failed' do
          expect_next_instance_of(GroupImportState) do |import|
            expect(import).to receive(:fail_op).and_call_original
          end

          expect { subject.perform(user.id, group.id) }.to raise_exception(Gitlab::ImportExport::Error)
        end
      end
    end
  end
end
