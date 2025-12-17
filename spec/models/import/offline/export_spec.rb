# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Export, feature_category: :importers do
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
end
