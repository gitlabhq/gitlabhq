# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Export, type: :model, feature_category: :importers do
  using RSpec::Parameterized::TableSyntax

  describe 'constants' do
    it 'correctly defines in progress statuses' do
      expect(described_class::IN_PROGRESS_STATUSES).to eq(
        [described_class::PENDING, described_class::STARTED]
      )
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:offline_export).class_name('Import::Offline::Export') }
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
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project) }

    describe '.for_status' do
      let(:export_1) { create(:bulk_import_export, :finished, relation: 'labels') }
      let(:export_2) { create(:bulk_import_export, :started, relation: 'user_contributions') }

      it 'returns bulk_import_exports for the given status' do
        expect(described_class.for_status(0)).to contain_exactly(export_2)
      end
    end

    describe '.for_offline_export' do
      let(:offline_export) { create(:offline_export) }
      let(:direct_transfer_relation_export) { create(:bulk_import_export) }
      let(:offline_transfer_relation_export) { create(:bulk_import_export, offline_export: offline_export) }

      it 'returns bulk_import_exports for the given offline export' do
        expect(described_class.for_offline_export(offline_export)).to contain_exactly(offline_transfer_relation_export)
      end

      it 'returns bulk_import_exports without an offline export when given nil' do
        expect(described_class.for_offline_export(nil)).to contain_exactly(direct_transfer_relation_export)
      end
    end

    describe '.for_offline_export_and_relation' do
      let_it_be(:offline_export) { create(:offline_export) }
      let_it_be(:export_1) { create(:bulk_import_export, offline_export: offline_export, relation: 'milestones') }
      let_it_be(:export_2) { create(:bulk_import_export, offline_export: offline_export, relation: 'labels') }
      let_it_be(:export_3) { create(:bulk_import_export, relation: 'milestones') }

      it 'returns exports for the given offline export and relation' do
        result = described_class.for_offline_export_and_relation(offline_export, 'milestones')

        expect(result).to contain_exactly(export_1)
      end
    end

    describe '.group_exports' do
      let_it_be(:group_export) { create(:bulk_import_export, group: group, project: nil) }
      let_it_be(:project_export) { create(:bulk_import_export, group: nil, project: project) }

      it 'returns only exports associated with a group' do
        expect(described_class.group_exports).to contain_exactly(group_export)
      end
    end

    describe '.project_exports' do
      let_it_be(:group_export) { create(:bulk_import_export, group: group, project: nil) }
      let_it_be(:project_export) { create(:bulk_import_export, group: nil, project: project) }

      it 'returns only exports associated with a project' do
        expect(described_class.project_exports).to contain_exactly(project_export)
      end
    end
  end

  describe '.find_or_create_user_contributions_export!' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project) }
    let_it_be(:offline_export) { create(:offline_export) }

    let(:uc_relation) { BulkImports::FileTransfer::BaseConfig::USER_CONTRIBUTIONS_RELATION }

    context 'when the export does not exist' do
      it 'creates a new export with pending status for a group' do
        export = described_class.find_or_create_user_contributions_export!(group, offline_export.id)

        expect(export).to be_persisted
        expect(export.group).to eq(group)
        expect(export.relation).to eq(uc_relation)
        expect(export.offline_export_id).to eq(offline_export.id)
        expect(export).to be_pending
      end

      it 'creates a new export with pending status for a project' do
        export = described_class.find_or_create_user_contributions_export!(project, offline_export.id)

        expect(export).to be_persisted
        expect(export.project).to eq(project)
        expect(export.relation).to eq(uc_relation)
        expect(export.offline_export_id).to eq(offline_export.id)
        expect(export).to be_pending
      end
    end

    context 'when the export already exists' do
      let_it_be(:existing_export) do
        create(:bulk_import_export, :finished, group: group, offline_export: offline_export,
          relation: 'user_contributions')
      end

      it 'returns the existing export without creating a new one' do
        expect { described_class.find_or_create_user_contributions_export!(group, offline_export.id) }
          .not_to change { described_class.count }

        export = described_class.find_or_create_user_contributions_export!(group, offline_export.id)
        expect(export.id).to eq(existing_export.id)
        expect(export).to be_finished
      end
    end

    context 'with invalid arguments' do
      let(:offline_export_id) { offline_export.id }

      where(:portable_arg, :offline_export_id_arg) do
        nil | ref(:offline_export_id)
        'invalid' | ref(:offline_export_id)
        ref(:group) | nil
        ref(:group) | 'invalid'
      end

      with_them do
        it 'raises ArgumentError' do
          expect do
            described_class.find_or_create_user_contributions_export!(portable_arg, offline_export_id_arg)
          end.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe 'state machine transitions', :clean_gitlab_redis_shared_state do
    describe '#finish!' do
      let_it_be(:project) { create(:project) }
      let_it_be(:offline_export) { create(:offline_export) }
      let(:export) { create(:bulk_import_export, :started, project: project) }

      subject(:finish_export) { export.finish! }

      it 'sets the status to finished' do
        expect { finish_export }.to change { export.status }.from(0).to(1)
      end

      context 'when the export is offline' do
        let(:cache_key) { "offline_export/#{offline_export.id}/Project/#{project.id}/user_contribution_ids" }
        let(:export) do
          create(:bulk_import_export, :started, project: project, offline_export: offline_export, relation: relation)
        end

        before do
          Gitlab::Cache::Import::Caching.set_add(cache_key, [1, 2, 3])
        end

        context 'and relation is not user_contributions' do
          let(:relation) { 'issues' }

          it 'does clear cached contributing user_ids' do
            expect { finish_export }.not_to change {
              Gitlab::Cache::Import::Caching.values_from_set(cache_key).length
            }.from(3)
          end
        end

        context 'and relation is user_contributions' do
          let(:relation) { 'user_contributions' }

          it 'clears cached contributing user_ids' do
            expect { finish_export }.to change {
              Gitlab::Cache::Import::Caching.values_from_set(cache_key).length
            }.from(3).to(0)
          end
        end
      end

      context 'when the export is not offline' do
        # Contributing users shouldn't be cached unless part of an offline export,
        # but these specs ensure the cache is cleared anyway
        let(:cache_key) { "offline_export//Project/#{project.id}/user_contribution_ids" }
        let(:export) { create(:bulk_import_export, :started, project: project, relation: relation) }

        before do
          Gitlab::Cache::Import::Caching.set_add(cache_key, [1, 2, 3])
        end

        context 'and relation is not user_contributions' do
          let(:relation) { 'issues' }

          it 'does not clear cached contributing user_ids' do
            expect { finish_export }.not_to change {
              Gitlab::Cache::Import::Caching.values_from_set(cache_key).length
            }.from(3)
          end
        end

        context 'and relation is user_contributions' do
          # Direct transfer doesn't create exports with user_contributions relation so this type of
          # export would never exist to call #finish! on in practice. This spec only exists for completeness
          let(:relation) { 'user_contributions' }

          it 'clears cached contributing user_ids' do
            expect { finish_export }.to change {
              Gitlab::Cache::Import::Caching.values_from_set(cache_key).length
            }.from(3).to(0)
          end
        end
      end
    end

    describe '#fail_op!' do
      context 'when export is for offline transfer' do
        let(:export) { create(:bulk_import_export, :offline) }

        subject(:fail_export) { export.fail_op! }

        it 'marks the offline export as failed' do
          expect { fail_export }
            .to change { export.offline_export.has_failures? }.from(false).to(true)
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

  describe '#offline?' do
    context 'when associated to an offline export' do
      subject(:export) { create(:bulk_import_export, :offline) }

      it { is_expected.to be_offline }
    end

    context 'when not associated to an offline export' do
      subject(:export) { create(:bulk_import_export) }

      it { is_expected.not_to be_offline }
    end
  end

  describe '#completed?' do
    where(:status, :expected_result) do
      :pending  | false
      :started  | false
      :finished | true
      :failed   | true
    end

    with_them do
      subject(:export) { build(:bulk_import_export, status) }

      it 'returns the expected result' do
        expect(export.completed?).to eq(expected_result)
      end
    end
  end
end
