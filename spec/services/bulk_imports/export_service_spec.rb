# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ExportService do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    group.add_owner(user)
  end

  subject { described_class.new(portable: group, user: user) }

  describe '#execute' do
    it 'schedules RelationExportWorker for each top level relation' do
      expect(subject).to receive(:execute).and_return(ServiceResponse.success).and_call_original
      top_level_relations = BulkImports::FileTransfer.config_for(group).portable_relations

      top_level_relations.each do |relation|
        expect(BulkImports::RelationExportWorker)
          .to receive(:perform_async)
          .with(user.id, group.id, group.class.name, relation)
      end

      subject.execute
    end

    context 'when exception occurs' do
      it 'does not schedule RelationExportWorker' do
        service = described_class.new(portable: nil, user: user)

        expect(service)
          .to receive(:execute)
          .and_return(ServiceResponse.error(message: 'Gitlab::ImportExport::Error', http_status: :unprocessible_entity))
          .and_call_original
        expect(BulkImports::RelationExportWorker).not_to receive(:perform_async)

        service.execute
      end
    end
  end
end
