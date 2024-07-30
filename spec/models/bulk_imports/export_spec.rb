# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Export, type: :model, feature_category: :importers do
  describe 'associations' do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_one(:upload) }
    it { is_expected.to have_many(:batches) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:relation) }
    it { is_expected.to validate_presence_of(:status) }

    context 'when not associated with a group or project' do
      it 'is invalid' do
        export = build(:bulk_import_export, group: nil, project: nil)

        expect(export).not_to be_valid
      end
    end

    context 'when associated with a group' do
      it 'is valid' do
        export = build(:bulk_import_export, group: build(:group), project: nil)

        expect(export).to be_valid
      end
    end

    context 'when associated with a project' do
      it 'is valid' do
        export = build(:bulk_import_export, group: nil, project: build(:project))

        expect(export).to be_valid
      end
    end

    context 'when relation is invalid' do
      it 'is invalid' do
        export = build(:bulk_import_export, relation: 'unsupported')

        expect(export).not_to be_valid
        expect(export.errors).to include(:relation)
      end
    end
  end

  describe 'scopes' do
    describe '.for_status' do
      let(:export_1) { create(:bulk_import_export, :finished, relation: 'labels') }
      let(:export_2) { create(:bulk_import_export, :started, relation: 'user_contributions') }

      it 'returns bulk_import_exports for the given status' do
        expect(described_class.for_status(0)).to contain_exactly(export_2)
      end
    end
  end

  describe 'state machine transitions', :clean_gitlab_redis_shared_state do
    describe '#finish!' do
      let_it_be(:project) { create(:project) }

      let(:export) { create(:bulk_import_export, :started, project: project) }
      let(:cache_key) { "bulk_imports/#{project.class.name}/#{project.id}/user_contribution_ids" }

      subject(:finish_export) { export.finish! }

      before do
        Gitlab::Cache::Import::Caching.set_add(cache_key, [1, 2, 3])
      end

      it 'sets the status to finished' do
        expect { finish_export }.to change { export.status }.from(0).to(1)
      end

      context 'when export is for user_contributions' do
        let(:export) { create(:bulk_import_export, :started, project: project, relation: 'user_contributions') }

        it 'clears cached contributing user_ids' do
          expect { finish_export }.to change {
            Gitlab::Cache::Import::Caching.values_from_set(cache_key).length
          }.from(3).to(0)
        end
      end

      context 'when export is not for user_contributions' do
        let(:export) { create(:bulk_import_export, :started, project: project, relation: 'issues') }

        it 'does clear cached contributing user_ids' do
          expect { finish_export }.not_to change {
            Gitlab::Cache::Import::Caching.values_from_set(cache_key).length
          }.from(3)
        end
      end
    end
  end

  describe '#portable' do
    context 'when associated with project' do
      it 'returns project' do
        export = create(:bulk_import_export, project: create(:project), group: nil)

        expect(export.portable).to be_instance_of(Project)
      end
    end

    context 'when associated with group' do
      it 'returns group' do
        export = create(:bulk_import_export)

        expect(export.portable).to be_instance_of(Group)
      end
    end
  end

  describe '#config' do
    context 'when associated with project' do
      it 'returns project config' do
        export = create(:bulk_import_export, project: create(:project), group: nil)

        expect(export.config).to be_instance_of(BulkImports::FileTransfer::ProjectConfig)
      end
    end

    context 'when associated with group' do
      it 'returns group config' do
        export = create(:bulk_import_export)

        expect(export.config).to be_instance_of(BulkImports::FileTransfer::GroupConfig)
      end
    end
  end

  describe '#remove_existing_upload!' do
    context 'when upload exists' do
      it 'removes the upload' do
        export = create(:bulk_import_export)
        upload = create(:bulk_import_export_upload, export: export)
        upload.update!(export_file: fixture_file_upload('spec/fixtures/bulk_imports/gz/labels.ndjson.gz'))

        expect_any_instance_of(BulkImports::ExportUpload) do |upload|
          expect(upload).to receive(:remove_export_file!)
          expect(upload).to receive(:save!)
        end

        export.remove_existing_upload!
      end
    end

    context 'when upload does not exist' do
      it 'returns' do
        export = build(:bulk_import_export)

        expect { export.remove_existing_upload! }.not_to change { export.upload }
      end
    end
  end

  describe '#relation_has_user_contributions?' do
    let(:export) { build(:bulk_import_export, project: build(:project), relation: relation) }

    subject { export.relation_has_user_contributions? }

    context 'when the relation has user contribitions' do
      let(:relation) { 'issues' }

      it { is_expected.to eq(true) }
    end

    context 'when the relation does not have user contribitions' do
      let(:relation) { 'labels' }

      it { is_expected.to eq(false) }
    end
  end
end
