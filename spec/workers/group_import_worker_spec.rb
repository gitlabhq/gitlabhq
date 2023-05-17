# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupImportWorker, feature_category: :importers do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  subject { described_class.new }

  before do
    create(:group_import_state, group: group, user: user)

    allow_next_instance_of(described_class) do |job|
      allow(job).to receive(:jid).and_return(SecureRandom.hex(8))
    end
  end

  describe 'sidekiq options' do
    it 'disables retry' do
      expect(described_class.sidekiq_options['retry']).to eq(false)
    end

    it 'disables dead' do
      expect(described_class.sidekiq_options['dead']).to eq(false)
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

      it 'updates the existing state' do
        expect { subject.perform(user.id, group.id) }
          .not_to change { GroupImportState.count }

        expect(group.import_state.reload).to be_finished
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
          expect { subject.perform(user.id, group.id) }.to raise_exception(Gitlab::ImportExport::Error)

          expect(group.import_state.reload.status).to eq(-1)
        end
      end
    end
  end
end
