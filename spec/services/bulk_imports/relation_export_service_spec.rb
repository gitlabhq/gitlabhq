# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::RelationExportService, feature_category: :importers do
  let_it_be(:jid) { 'jid' }
  let_it_be(:relation) { 'labels' }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }
  let_it_be(:label) { create(:group_label, group: group) }
  let_it_be(:export_path) { "#{Dir.tmpdir}/relation_export_service_spec/tree" }
  let_it_be_with_reload(:export) { create(:bulk_import_export, group: group, relation: relation, user: user) }

  before do
    FileUtils.mkdir_p(export_path)

    group.add_owner(user)
    project.add_maintainer(user)

    allow(subject).to receive(:export_path).and_return(export_path)
  end

  after :all do
    FileUtils.rm_rf(export_path)
  end

  subject { described_class.new(user, group, relation, jid) }

  describe '#execute' do
    it 'exports specified relation and marks export as finished' do
      expect_next_instance_of(BulkImports::TreeExportService) do |service|
        expect(service).to receive(:execute).and_call_original
      end

      subject.execute

      expect(export.reload.upload.export_file).to be_present
      expect(export.finished?).to eq(true)
      expect(export.batched?).to eq(false)
      expect(export.batches_count).to eq(0)
      expect(export.batches.count).to eq(0)
      expect(export.total_objects_count).to eq(1)
    end

    it 'removes temp export files' do
      subject.execute

      expect(Dir.exist?(export_path)).to eq(false)
    end

    it 'exports specified relation and marks export as finished' do
      subject.execute

      expect(export.upload.export_file).to be_present
    end

    context 'when relation is empty and there is nothing to export' do
      let(:relation) { 'milestones' }

      it 'creates empty file on disk' do
        expect(FileUtils).to receive(:touch).with("#{export_path}/#{relation}.ndjson").and_call_original

        subject.execute
      end
    end

    context 'when exporting a file relation' do
      it 'uses file export service' do
        service = described_class.new(user, project, 'uploads', jid)

        expect_next_instance_of(BulkImports::FileExportService) do |service|
          expect(service).to receive(:execute)
        end

        service.execute
      end
    end

    context 'when export record does not exist' do
      let(:another_group) { create(:group) }

      subject { described_class.new(user, another_group, relation, jid) }

      it 'creates export record' do
        another_group.add_owner(user)

        expect { subject.execute }
          .to change { another_group.bulk_import_exports.count }
          .from(0)
          .to(1)
      end
    end

    context 'when there is existing export present' do
      let(:upload) { create(:bulk_import_export_upload, export: export) }

      it 'removes existing export before exporting' do
        upload.update!(export_file: fixture_file_upload('spec/fixtures/bulk_imports/gz/labels.ndjson.gz'))

        expect_any_instance_of(BulkImports::ExportUpload) do |upload|
          expect(upload).to receive(:remove_export_file!)
        end

        subject.execute
      end

      context 'when export is recently finished' do
        it 'returns recently finished export instead of re-exporting' do
          updated_at = 5.seconds.ago
          export.update!(status: 1, updated_at: updated_at)

          expect { subject.execute }.not_to change { export.updated_at }

          expect(export.status).to eq(1)
          expect(export.updated_at).to eq(updated_at)
        end
      end
    end

    context 'when export was batched' do
      let(:relation) { 'milestones' }
      let(:export) do
        create(:bulk_import_export, group: group, user: user, relation: relation, batched: true, batches_count: 2)
      end

      it 'removes existing batches and marks export as not batched' do
        create(:bulk_import_export_batch, batch_number: 1, export: export)
        create(:bulk_import_export_batch, batch_number: 2, export: export)

        expect { described_class.new(user, group, relation, jid).execute }
          .to change { export.reload.batches.count }
          .from(2)
          .to(0)

        expect(export.batched?).to eq(false)
        expect(export.batches_count).to eq(0)
      end
    end
  end
end
