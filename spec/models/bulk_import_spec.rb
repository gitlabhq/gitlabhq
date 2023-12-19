# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImport, type: :model, feature_category: :importers do
  let_it_be(:created_bulk_import) { create(:bulk_import, :created, updated_at: 2.hours.ago) }
  let_it_be(:started_bulk_import) { create(:bulk_import, :started, updated_at: 3.hours.ago) }
  let_it_be(:finished_bulk_import) { create(:bulk_import, :finished, updated_at: 1.hour.ago) }
  let_it_be(:failed_bulk_import) { create(:bulk_import, :failed) }
  let_it_be(:stale_created_bulk_import) { create(:bulk_import, :created, updated_at: 3.days.ago) }
  let_it_be(:stale_started_bulk_import) { create(:bulk_import, :started, updated_at: 2.days.ago) }

  describe 'associations' do
    it { is_expected.to belong_to(:user).required }
    it { is_expected.to have_one(:configuration) }
    it { is_expected.to have_many(:entities) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:source_type) }
    it { is_expected.to validate_presence_of(:status) }

    it { is_expected.to define_enum_for(:source_type).with_values(%i[gitlab]) }
  end

  describe 'scopes' do
    describe '.stale' do
      subject { described_class.stale }

      it { is_expected.to contain_exactly(stale_created_bulk_import, stale_started_bulk_import) }
    end

    describe '.order_by_updated_at_and_id' do
      subject { described_class.order_by_updated_at_and_id(:desc) }

      it 'sorts by given direction' do
        is_expected.to eq([
          failed_bulk_import,
          finished_bulk_import,
          created_bulk_import,
          started_bulk_import,
          stale_started_bulk_import,
          stale_created_bulk_import
        ])
      end
    end
  end

  describe '.all_human_statuses' do
    it 'returns all human readable entity statuses' do
      expect(described_class.all_human_statuses).to contain_exactly('created', 'started', 'finished', 'failed', 'timeout')
    end
  end

  describe '.min_gl_version_for_project' do
    it { expect(described_class.min_gl_version_for_project_migration).to be_a(Gitlab::VersionInfo) }
    it { expect(described_class.min_gl_version_for_project_migration.to_s).to eq('14.4.0') }
  end

  describe '#completed?' do
    it { expect(described_class.new(status: -1)).to be_completed }
    it { expect(described_class.new(status: 0)).not_to be_completed }
    it { expect(described_class.new(status: 1)).not_to be_completed }
    it { expect(described_class.new(status: 2)).to be_completed }
    it { expect(described_class.new(status: 3)).to be_completed }
  end

  describe '#source_version_info' do
    it 'returns source_version as Gitlab::VersionInfo' do
      bulk_import = build(:bulk_import, source_version: '9.13.2')

      expect(bulk_import.source_version_info).to be_a(Gitlab::VersionInfo)
      expect(bulk_import.source_version_info.to_s).to eq(bulk_import.source_version)
    end
  end

  describe '#update_has_failures' do
    let(:import) { create(:bulk_import, :started) }
    let(:entity) { create(:bulk_import_entity, bulk_import: import) }

    context 'when entity has failures' do
      it 'sets has_failures flag to true' do
        expect(import.has_failures).to eq(false)

        entity.update!(has_failures: true)
        import.fail_op!

        expect(import.has_failures).to eq(true)
      end
    end

    context 'when entity does not have failures' do
      it 'sets has_failures flag to false' do
        expect(import.has_failures).to eq(false)

        entity.update!(has_failures: false)
        import.fail_op!

        expect(import.has_failures).to eq(false)
      end
    end
  end

  describe '#supports_batched_export?' do
    context 'when source version is greater than min supported version for batched migrations' do
      it 'returns true' do
        bulk_import = build(:bulk_import, source_version: '16.2.0')

        expect(bulk_import.supports_batched_export?).to eq(true)
      end
    end

    context 'when source version is less than min supported version for batched migrations' do
      it 'returns false' do
        bulk_import = build(:bulk_import, source_version: '15.5.0')

        expect(bulk_import.supports_batched_export?).to eq(false)
      end
    end
  end
end
