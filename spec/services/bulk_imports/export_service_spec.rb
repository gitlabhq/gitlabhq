# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ExportService, feature_category: :importers do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, owner_of: group) }

  subject { described_class.new(portable: group, user: user) }

  describe '#execute' do
    let_it_be(:top_level_relations) { BulkImports::FileTransfer.config_for(group).portable_relations }

    before do
      allow(subject).to receive(:execute).and_return(ServiceResponse.success).and_call_original
    end

    context 'when export is not batched' do
      it 'schedules RelationExportWorker for each top level relation' do
        top_level_relations.each do |relation|
          expect(BulkImports::RelationExportWorker)
            .to receive(:perform_async)
            .with(
              user.id,
              group.id,
              group.class.name,
              relation,
              false,
              { 'offline_export_id' => nil }
            )
        end

        subject.execute
      end
    end

    context 'when export is batched' do
      subject { described_class.new(portable: group, user: user, batched: true) }

      it 'schedules RelationExportWorker with a `batched: true` flag' do
        top_level_relations.each do |relation|
          expect(BulkImports::RelationExportWorker)
            .to receive(:perform_async)
            .with(
              user.id,
              group.id,
              group.class.name,
              relation,
              true,
              { 'offline_export_id' => nil }
            )
        end

        subject.execute
      end
    end

    context 'when export is from offline transfer' do
      subject(:service) { described_class.new(portable: group, user: user, offline_export_id: 123) }

      it 'schedules RelationExportWorker with the offline export ID' do
        top_level_relations.each do |relation|
          expect(BulkImports::RelationExportWorker)
            .to receive(:perform_async)
              .with(
                user.id,
                group.id,
                group.class.name,
                relation,
                false,
                { 'offline_export_id' => 123 }
              )
        end

        service.execute
      end
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

      context 'when user is not allowed to perform export' do
        let(:another_user) { create(:user) }

        it 'does not schedule RelationExportWorker' do
          another_user = create(:user)
          service = described_class.new(portable: group, user: another_user)
          response = service.execute

          expect(response.status).to eq(:error)
          expect(response.http_status).to eq(:unprocessable_entity)
          expect(response.message).to include(
            "User with ID: #{another_user.id} does not have required permissions for Group"
          )
        end
      end
    end
  end
end
