# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Export, feature_category: :importers do
  using RSpec::Parameterized::TableSyntax

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to have_one(:configuration).class_name('Import::Offline::Configuration') }
    it { is_expected.to have_many(:bulk_import_exports).class_name('BulkImports::Export') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:source_hostname) }
    it { is_expected.to validate_presence_of(:status) }

    describe '#source_hostname' do
      it { is_expected.to allow_value('http://example.com:8080').for(:source_hostname) }
      it { is_expected.to allow_value('https://example.com:8080').for(:source_hostname) }
      it { is_expected.to allow_value('http://example.com').for(:source_hostname) }
      it { is_expected.to allow_value('https://example.com').for(:source_hostname) }
      it { is_expected.not_to allow_value('http://').for(:source_hostname) }
      it { is_expected.not_to allow_value('example.com').for(:source_hostname) }
      it { is_expected.not_to allow_value('https://example.com/dir').for(:source_hostname) }
      it { is_expected.not_to allow_value('https://example.com?param=1').for(:source_hostname) }
      it { is_expected.not_to allow_value('https://example.com/dir?param=1').for(:source_hostname) }
      it { is_expected.not_to allow_value('https://github.com').for(:source_hostname) }
      it { is_expected.not_to allow_value('https://www.github.com').for(:source_hostname) }
      it { is_expected.not_to allow_value('https://bitbucket.org').for(:source_hostname) }
      it { is_expected.not_to allow_value('https://gitea.com').for(:source_hostname) }
    end
  end

  describe 'scopes' do
    describe '.order_by_created_at' do
      let_it_be(:export_1) { create(:offline_export, created_at: 3.days.ago) }
      let_it_be(:export_2) { create(:offline_export, created_at: 2.days.ago) }
      let_it_be(:export_3) { create(:offline_export, created_at: 1.day.ago) }

      it 'orders exports by created_at in ascending order' do
        expect(described_class.order_by_created_at(:asc)).to eq([export_1, export_2, export_3])
      end

      it 'orders exports by created_at in descending order' do
        expect(described_class.order_by_created_at(:desc)).to eq([export_3, export_2, export_1])
      end
    end
  end

  describe '.all_human_statuses' do
    it 'returns all human readable entity statuses' do
      expect(described_class.all_human_statuses)
        .to contain_exactly('created', 'started', 'finished', 'failed')
    end
  end

  describe 'configuration purge' do
    let_it_be(:export) { create(:offline_export, :started) }
    let_it_be(:configuration) { create(:offline_configuration, offline_export: export) }

    describe 'after transitioning to finished' do
      it 'schedules configuration purge worker' do
        expect(Import::Offline::ConfigurationPurgeWorker)
          .to receive(:perform_in)
          .with(described_class::PURGE_CONFIGURATION_DELAY, configuration.id)

        export.finish
      end

      context 'when export has no configuration' do
        let_it_be(:export_without_config) { create(:offline_export) }

        it 'does not schedule configuration purge worker' do
          expect(Import::Offline::ConfigurationPurgeWorker).not_to receive(:perform_in)

          export_without_config.finish
        end
      end
    end

    describe 'after transitioning to failed' do
      it 'schedules configuration purge worker' do
        expect(Import::Offline::ConfigurationPurgeWorker)
          .to receive(:perform_in)
          .with(described_class::PURGE_CONFIGURATION_DELAY, configuration.id)

        export.fail_op
      end

      context 'when export has no configuration' do
        let_it_be(:export_without_config) { create(:offline_export) }

        it 'does not schedule configuration purge worker' do
          export_without_config.start

          expect(Import::Offline::ConfigurationPurgeWorker).not_to receive(:perform_in)

          export_without_config.fail_op
        end
      end
    end
  end

  describe '#completed?' do
    where(:status_trait, :expected_result) do
      :created  | false
      :started  | false
      :finished | true
      :failed   | true
    end

    with_them do
      subject(:export) { build(:offline_export, status_trait) }

      it 'returns the expected result' do
        expect(export.completed?).to eq(expected_result)
      end
    end
  end

  describe '#update_has_failures!' do
    subject(:export) { create(:offline_export, has_failures: has_failures) }

    context 'when has_failures is currently false' do
      let(:has_failures) { false }

      it 'sets the has_failures flag to true' do
        expect { export.update_has_failures! }
          .to change { export.has_failures }
          .from(false).to(true)
      end
    end

    context 'when has_failures is currently true' do
      let(:has_failures) { true }

      it 'leaves the has_failures flag unchanged' do
        expect { export.update_has_failures! }
          .not_to change { export.has_failures }
      end
    end
  end

  describe 'included routes methods' do
    let_it_be(:export) { create(:offline_export) }
    let_it_be(:included_project_1) { create(:project) }
    let_it_be(:included_project_2) { create(:project) }
    let_it_be(:excluded_project) { create(:project) }
    let_it_be(:included_group_1) { create(:group) }
    let_it_be(:included_group_2) { create(:group) }
    let_it_be(:excluded_group) { create(:group) }

    before_all do
      # Create finished group and project relations belonging to offline_export
      create(:bulk_import_export, :finished, offline_export: export, project: included_project_1)
      create(:bulk_import_export, :finished, offline_export: export, project: included_project_2)
      create(:bulk_import_export, :finished, offline_export: export, group: included_group_1)
      create(:bulk_import_export, :finished, offline_export: export, group: included_group_2)

      # Create group and project relation exports not in finished status
      create(:bulk_import_export, :pending, offline_export: export, project: excluded_project, relation: 'milestones')
      create(:bulk_import_export, :started, offline_export: export, project: excluded_project, relation: 'issues')
      create(:bulk_import_export, :failed, offline_export: export, project: excluded_project, relation: 'snippets')
      create(:bulk_import_export, :pending, offline_export: export, group: excluded_group, relation: 'milestones')
      create(:bulk_import_export, :started, offline_export: export, group: excluded_group, relation: 'badges')
      create(:bulk_import_export, :failed, offline_export: export, group: excluded_group, relation: 'boards')

      # Create finished group and project relation exports for other offline exports
      create(:bulk_import_export, :offline, :finished, project: excluded_project)
      create(:bulk_import_export, :offline, :finished, group: excluded_group)
    end

    describe '#included_group_routes' do
      subject(:included_group_routes) { export.included_group_routes }

      it 'returns group routes for finished group relation exports belonging to the offline export' do
        expect(included_group_routes).to contain_exactly(included_group_1.route, included_group_2.route)
      end
    end

    describe '#included_project_routes' do
      subject(:included_project_routes) { export.included_project_routes }

      it 'returns project routes for finished project relation exports belonging to the offline export' do
        expect(included_project_routes).to contain_exactly(included_project_1.route, included_project_2.route)
      end
    end
  end
end
