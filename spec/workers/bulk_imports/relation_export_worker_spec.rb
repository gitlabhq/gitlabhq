# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::RelationExportWorker do
  let_it_be(:jid) { 'jid' }
  let_it_be(:relation) { 'labels' }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:job_args) { [user.id, group.id, group.class.name, relation] }

  describe '#perform' do
    include_examples 'an idempotent worker' do
      context 'when export record does not exist' do
        let(:another_group) { create(:group) }
        let(:job_args) { [user.id, another_group.id, another_group.class.name, relation] }

        it 'creates export record' do
          another_group.add_owner(user)

          expect { perform_multiple(job_args) }
            .to change { another_group.bulk_import_exports.count }
            .from(0)
            .to(1)
        end
      end

      it 'executes RelationExportService' do
        group.add_owner(user)

        service = instance_double(BulkImports::RelationExportService)

        expect(BulkImports::RelationExportService)
          .to receive(:new)
          .with(user, group, relation, anything)
          .twice
          .and_return(service)
        expect(service)
          .to receive(:execute)
          .twice

        perform_multiple(job_args)
      end
    end
  end
end
