# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Exports::WriteMetadataService, feature_category: :importers do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let_it_be(:offline_export) { create(:offline_export, :started, :with_configuration) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    let_it_be_with_reload(:failed_group_self_export) do
      create(:bulk_import_export, :failed, group: group, offline_export: offline_export, relation: 'self')
    end

    let_it_be_with_reload(:failed_project_self_export) do
      create(:bulk_import_export, :failed, project: project, offline_export: offline_export, relation: 'self')
    end

    let_it_be_with_reload(:finished_group_labels_export) do
      create(:bulk_import_export, :finished, group: group, offline_export: offline_export, relation: 'labels')
    end

    let_it_be_with_reload(:finished_project_issues_export) do
      create(:bulk_import_export, :finished, project: project, offline_export: offline_export, relation: 'issues')
    end

    subject(:service) { described_class.new(offline_export) }

    shared_examples 'a successful metadata export' do
      let(:expected_entities_mapping) do
        {
          group.full_path => "group_#{group.id}",
          project.full_path => "project_#{project.id}"
        }
      end

      let(:tmpdir) { Dir.mktmpdir }

      after do
        FileUtils.rm_rf(tmpdir)
      end

      it 'generates offline export metadata correctly' do
        expect_next_instance_of(Gitlab::ImportExport::Json::NdjsonWriter) do |json_writer|
          expect(json_writer).to receive(:write_attributes).with(
            described_class::METADATA_FILENAME,
            {
              'instance_version' => Gitlab::VERSION,
              'instance_enterprise' => Gitlab.ee?,
              'export_prefix' => offline_export.configuration.export_prefix,
              'source_hostname' => Gitlab.config.gitlab.url,
              'entities_mapping' => hash_including(expected_entities_mapping)
            }
          ).and_call_original
        end

        service.execute
      end

      it 'removes temp files' do
        expect(Dir).to receive(:mktmpdir).with(described_class::TMPDIR).and_return(tmpdir)

        service.execute

        expect(Dir.exist?(tmpdir)).to be(false)
      end
    end

    context 'when entities have at least one completed relation export' do
      it_behaves_like 'a successful metadata export'
    end

    context 'when a project has no finished relation exports' do
      before do
        finished_project_issues_export.fail_op!
      end

      it_behaves_like 'a successful metadata export' do
        let(:expected_entities_mapping) { { group.full_path => "group_#{group.id}" } }
      end
    end

    context 'when a group has no finished relation exports' do
      before do
        finished_group_labels_export.fail_op!
      end

      it_behaves_like 'a successful metadata export' do
        let(:expected_entities_mapping) { { project.full_path => "project_#{project.id}" } }
      end
    end

    context 'when there are no finished relation exports for any entities' do
      before do
        offline_export.bulk_import_exports.map(&:fail_op!)
      end

      it 'returns nil' do
        expect(service.execute).to be_nil
      end
    end

    context 'when offline_export is not present' do
      let(:offline_export) { nil }

      it 'returns nil' do
        expect(service.execute).to be_nil
      end
    end

    context 'when offline_export status is not started' do
      where(:status) do
        Import::Offline::Export.state_machine.states.map(&:name).excluding(:started)
      end

      with_them do
        let(:offline_export) { create(:offline_export, status, :with_configuration) }

        it 'returns nil' do
          expect(service.execute).to be_nil
        end
      end
    end
  end
end
