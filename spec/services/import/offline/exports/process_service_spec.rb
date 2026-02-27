# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Exports::ProcessService, feature_category: :importers do
  describe '#execute' do
    let_it_be_with_reload(:offline_export) { create(:offline_export, :with_configuration) }
    let_it_be(:group_1) { create(:group) }
    let_it_be(:subgroup_1) { create(:group, parent: group_1) }
    let_it_be(:project_1) { create(:project, group: subgroup_1) }
    let_it_be(:subgroup_2) { create(:group, parent: group_1) }
    let_it_be(:project_2) { create(:project, group: group_1) }
    let_it_be(:group_2) { create(:group) }
    let_it_be(:project_3) { create(:project) }

    subject(:service) { described_class.new(offline_export) }

    before_all do
      [group_1, subgroup_1, subgroup_2, group_2].each do |group|
        group.add_owner(offline_export.user)
      end

      [project_1, project_2].each do |project|
        project.add_maintainer(offline_export.user)
      end
    end

    shared_examples 'a finished export', :aggregate_failures do
      it 'does not re-enqueue itself or process relation exports' do
        expect(Import::Offline::ExportWorker).not_to receive(:perform_in)
        expect(BulkImports::ExportService).not_to receive(:new)

        service.execute
      end
    end

    shared_examples 'a processing export', :aggregate_failures do
      it 're-enqueues itself' do
        expect(Import::Offline::ExportWorker).to receive(:perform_in).with(
          described_class::PERFORM_DELAY, offline_export.id
        )

        service.execute
      end
    end

    context 'when offline_export is not present' do
      let(:offline_export) { nil }

      it_behaves_like 'a finished export'
    end

    context 'when offline_export is finished' do
      before do
        offline_export.update!(status: 2)
      end

      it_behaves_like 'a finished export'
    end

    context 'when offline_export is failed' do
      before do
        offline_export.update!(status: -1)
      end

      it_behaves_like 'a finished export'
    end

    context 'when all relation exports have failed' do
      let_it_be(:bulk_import_exports) { create_list(:bulk_import_export, 2, :failed, offline_export: offline_export) }

      it 'marks offline_export as failed' do
        expect { service.execute }.to change { offline_export.reload.status_name }.to(:failed)
      end

      it_behaves_like 'a finished export'
    end

    context 'when offline export is created' do
      let_it_be(:self_export_group_1) { create_self_relation_export(:pending, group: group_1) }
      let_it_be(:self_export_group_2) { create_self_relation_export(:pending, group: group_2) }
      let_it_be(:self_export_project_3) { create_self_relation_export(:pending, project: project_3) }

      it_behaves_like 'a processing export'

      it 'starts the offline export' do
        expect { service.execute }.to change { offline_export.reload.status_name }.to(:started)
      end

      it "begins exporting all portables with 'self' relation in pending status" do
        shared_export_service_args = {
          user: offline_export.user,
          batched: true,
          offline_export_id: offline_export.id
        }

        allow(BulkImports::ExportService).to receive(:new).and_call_original

        expect(BulkImports::ExportService).to receive(:new).with(
          portable: self_export_group_1.portable, **shared_export_service_args
        ).once.and_call_original

        expect(BulkImports::ExportService).to receive(:new).with(
          portable: self_export_group_2.portable, **shared_export_service_args
        ).once.and_call_original

        expect(BulkImports::ExportService).to receive(:new).with(
          portable: self_export_project_3.portable, **shared_export_service_args
        ).once.and_call_original

        service.execute
      end

      it "creates 'self' relation export records for all descendant portables", :aggregate_failures do
        expect { service.execute }.to change { BulkImports::Export.count }.by(4)

        expect(
          BulkImports::Export.for_offline_export_and_relation(offline_export, 'self').pluck(:group_id)
        ).to include(*[group_1, group_2, subgroup_1, subgroup_2].map(&:id))

        expect(
          BulkImports::Export.for_offline_export_and_relation(offline_export, 'self').pluck(:project_id)
        ).to include(*[project_1, project_2].map(&:id))
      end

      context 'and a portable is a descendant of another portable' do
        it "does not create duplicate 'self' relation export records" do
          create(:bulk_import_export, :pending, offline_export: offline_export, group: subgroup_1, relation: 'self')

          expect { service.execute }.not_to raise_error

          subgroup_1_exports = BulkImports::Export.where(
            offline_export: offline_export,
            relation: 'self',
            group_id: subgroup_1.id
          )
          expect(subgroup_1_exports.count).to eq(1)

          project_1_exports = BulkImports::Export.where(
            offline_export: offline_export,
            relation: 'self',
            project_id: project_1.id
          )
          expect(project_1_exports.count).to eq(1)
        end
      end

      context 'when there are no descendent portables' do
        let_it_be(:offline_export) { create(:offline_export) }
        let_it_be(:bulk_export) do
          create(
            :bulk_import_export, :pending, offline_export: offline_export,
            group: group_2, relation: 'self'
          )
        end

        it 'does not create any additional exports' do
          expect { service.execute }.not_to change { BulkImports::Export.count }
        end
      end
    end

    context 'when offline export is started' do
      before do
        offline_export.update!(status: 1)
      end

      context 'and all relation exports are complete' do
        let_it_be(:bulk_import_exports) do
          [
            create_self_relation_export(:finished, group: group_1),
            create_self_relation_export(:failed, group: group_2)
          ]
        end

        it_behaves_like 'a finished export'

        it 'finishes the offline export' do
          expect { service.execute }.to change { offline_export.reload.status_name }.to(:finished)
        end

        it 'generates metadata.json' do
          write_metadata_service_double = instance_double(Import::Offline::Exports::WriteMetadataService)

          expect(Import::Offline::Exports::WriteMetadataService).to receive(:new)
            .with(offline_export).and_return(write_metadata_service_double)

          expect(write_metadata_service_double).to receive(:execute)

          service.execute
        end
      end

      context 'and not all relation exports are complete' do
        let_it_be(:self_export_group_1) { create_self_relation_export(:pending, group: group_1) }
        let_it_be(:self_export_subgroup_1) { create_self_relation_export(:started, group: subgroup_1) }
        let_it_be(:self_export_project_1) { create_self_relation_export(:finished, project: project_1) }
        let_it_be(:self_export_group_2) { create_self_relation_export(:failed, group: group_2) }

        it_behaves_like 'a processing export'

        it 'does not update offline export status' do
          expect { service.execute }.not_to change { offline_export.reload.status_name }.from(:started)
        end

        it "does not create new 'self' relations" do
          expect { service.execute }.not_to change { BulkImports::Export.count }
        end

        it "only begins exporting relations for portables with pending 'self' relation exports" do
          shared_export_service_args = {
            user: offline_export.user,
            batched: true,
            offline_export_id: offline_export.id
          }
          expect(BulkImports::ExportService).to receive(:new).with(
            portable: self_export_group_1.portable, **shared_export_service_args
          ).once.and_call_original

          expect(BulkImports::ExportService).not_to receive(:new).with(
            portable: subgroup_1, **shared_export_service_args
          )

          expect(BulkImports::ExportService).not_to receive(:new).with(
            portable: project_1, **shared_export_service_args
          )

          expect(BulkImports::ExportService).not_to receive(:new).with(
            portable: subgroup_2, **shared_export_service_args
          )

          service.execute
        end

        context 'and the user lacks permissions to export a portable' do
          before do
            group_1.members.find_by(user: offline_export.user).update!(access_level: Gitlab::Access::GUEST)
          end

          it "fails the 'self' relation export" do
            expect { service.execute }.to change { self_export_group_1.reload.status_name }.to(:failed)
          end
        end
      end
    end

    def create_self_relation_export(status, group: nil, project: nil)
      create(
        :bulk_import_export, status, offline_export: offline_export,
        group: group, project: project, relation: 'self'
      )
    end
  end
end
