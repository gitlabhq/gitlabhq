# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Observability::GroupExportWorker, feature_category: :observability do
  describe '#perform' do
    let_it_be(:group) { create(:group) }
    let(:group_id) { group.id }
    let(:job_args) { [group_id] }

    subject(:perform_export) { described_class.new.perform(*job_args) }

    before do
      allow(Ci::Observability::ExportWorker).to receive(:bulk_perform_async_with_contexts)
    end

    context 'when group does not exist' do
      let(:group_id) { non_existing_record_id }

      it 'does not raise an error' do
        expect { perform_export }.not_to raise_error
      end

      it 'does not enqueue any ExportWorker jobs' do
        perform_export

        expect(Ci::Observability::ExportWorker).not_to have_received(:bulk_perform_async_with_contexts)
      end
    end

    context 'when group exists' do
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:old_pipeline) { create(:ci_pipeline, :success, project: project, created_at: 15.days.ago) }
      let_it_be(:recent_pipeline) { create(:ci_pipeline, :success, project: project, created_at: 5.days.ago) }
      let_it_be(:running_pipeline) { create(:ci_pipeline, :running, project: project, created_at: 2.days.ago) }

      it 'enqueues ExportWorker for completed pipelines from the past 10 days' do
        perform_export

        expect(Ci::Observability::ExportWorker).to have_received(:bulk_perform_async_with_contexts) do |pipeline_ids,
          arguments_proc:,
          context_proc:|
          expect(pipeline_ids).to match_array([recent_pipeline.id])
          expect(pipeline_ids).not_to include(old_pipeline.id)
          expect(pipeline_ids).not_to include(running_pipeline.id)

          pipeline_ids.each do |pipeline_id|
            expect(arguments_proc.call(pipeline_id)).to eq([pipeline_id])
            expect(context_proc.call(pipeline_id)).to eq({})
          end
        end
      end

      context 'with subgroups' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:subgroup_project) { create(:project, group: subgroup) }
        let_it_be(:subgroup_pipeline) do
          create(:ci_pipeline, :success, project: subgroup_project, created_at: 4.days.ago)
        end

        context 'when subgroup does not have group_o11y_setting' do
          it 'enqueues ExportWorker for subgroup projects' do
            perform_export

            expect(Ci::Observability::ExportWorker).to have_received(:bulk_perform_async_with_contexts) do
              |pipeline_ids, arguments_proc:, context_proc:|
              expect(pipeline_ids).to match_array([recent_pipeline.id, subgroup_pipeline.id])
              expect(arguments_proc).to be_a(Proc)
              expect(context_proc).to be_a(Proc)
            end
          end
        end

        context 'when subgroup has group_o11y_setting' do
          let_it_be(:group_o11y_setting) { create(:observability_group_o11y_setting, group: subgroup) }

          it 'skips subgroup and its projects' do
            perform_export

            expect(Ci::Observability::ExportWorker).to have_received(:bulk_perform_async_with_contexts) do
              |pipeline_ids, arguments_proc:, context_proc:|
              expect(pipeline_ids).to match_array([recent_pipeline.id])
              expect(pipeline_ids).not_to include(subgroup_pipeline.id)
              expect(arguments_proc).to be_a(Proc)
              expect(context_proc).to be_a(Proc)
            end
          end
        end

        context 'with nested subgroups' do
          let_it_be(:nested_subgroup) { create(:group, parent: subgroup) }
          let_it_be(:nested_project) { create(:project, group: nested_subgroup) }
          let_it_be(:nested_pipeline) do
            create(:ci_pipeline, :success, project: nested_project, created_at: 6.days.ago)
          end

          context 'when nested subgroup does not have group_o11y_setting' do
            it 'enqueues ExportWorker for nested subgroup projects' do
              perform_export

              expect(Ci::Observability::ExportWorker).to have_received(:bulk_perform_async_with_contexts) do
              |pipeline_ids, arguments_proc:, context_proc:|
                expect(pipeline_ids).to match_array([recent_pipeline.id, subgroup_pipeline.id, nested_pipeline.id])
                expect(arguments_proc).to be_a(Proc)
                expect(context_proc).to be_a(Proc)
              end
            end
          end

          context 'when nested subgroup has group_o11y_setting' do
            let_it_be(:nested_group_o11y_setting) { create(:observability_group_o11y_setting, group: nested_subgroup) }

            it 'skips nested subgroup but processes parent subgroup' do
              perform_export

              expect(Ci::Observability::ExportWorker).to have_received(:bulk_perform_async_with_contexts) do
                |pipeline_ids, arguments_proc:, context_proc:|
                expect(pipeline_ids).to match_array([recent_pipeline.id, subgroup_pipeline.id])
                expect(pipeline_ids).not_to include(nested_pipeline.id)
                expect(arguments_proc).to be_a(Proc)
                expect(context_proc).to be_a(Proc)
              end
            end
          end

          context 'when parent subgroup has group_o11y_setting' do
            let_it_be(:parent_group_o11y_setting) { create(:observability_group_o11y_setting, group: subgroup) }

            it 'skips parent subgroup and nested subgroup' do
              perform_export

              expect(Ci::Observability::ExportWorker).to have_received(:bulk_perform_async_with_contexts) do
                |pipeline_ids, arguments_proc:, context_proc:|
                expect(pipeline_ids).to match_array([recent_pipeline.id])
                expect(pipeline_ids).not_to include(subgroup_pipeline.id)
                expect(pipeline_ids).not_to include(nested_pipeline.id)
                expect(arguments_proc).to be_a(Proc)
                expect(context_proc).to be_a(Proc)
              end
            end
          end
        end
      end

      context 'with different pipeline statuses' do
        let_it_be(:failed_pipeline) { create(:ci_pipeline, :failed, project: project, created_at: 7.days.ago) }
        let_it_be(:canceled_pipeline) { create(:ci_pipeline, :canceled, project: project, created_at: 8.days.ago) }
        let_it_be(:skipped_pipeline) { create(:ci_pipeline, :skipped, project: project, created_at: 9.days.ago) }

        it 'enqueues ExportWorker for all completed statuses' do
          perform_export

          expect(Ci::Observability::ExportWorker).to have_received(:bulk_perform_async_with_contexts) do
          |pipeline_ids, arguments_proc:, context_proc:|
            expect(pipeline_ids).to match_array([
              recent_pipeline.id,
              failed_pipeline.id,
              canceled_pipeline.id,
              skipped_pipeline.id
            ])
            expect(arguments_proc).to be_a(Proc)
            expect(context_proc).to be_a(Proc)
          end
        end
      end

      context 'with custom days_ago parameter' do
        let_it_be(:pipeline_3_days_ago) { create(:ci_pipeline, :success, project: project, created_at: 3.days.ago) }
        let_it_be(:pipeline_7_days_ago) { create(:ci_pipeline, :success, project: project, created_at: 7.days.ago) }

        let(:job_args) { [group_id, { collection_window_lookback_days: 5 }] }

        it 'enqueues ExportWorker only for pipelines from the past days_ago days' do
          perform_export

          expect(Ci::Observability::ExportWorker).to have_received(:bulk_perform_async_with_contexts) do
            |pipeline_ids, arguments_proc:, context_proc:|
            expect(pipeline_ids).to match_array([pipeline_3_days_ago.id])
            expect(pipeline_ids).not_to include(pipeline_7_days_ago.id)
            expect(arguments_proc).to be_a(Proc)
            expect(context_proc).to be_a(Proc)
          end
        end
      end

      shared_examples 'does not enqueue any ExportWorker jobs' do
        it 'does not enqueue any ExportWorker jobs' do
          perform_export

          expect(Ci::Observability::ExportWorker).not_to have_received(:bulk_perform_async_with_contexts)
        end
      end

      context 'with invalid days_ago parameter' do
        context 'when days_ago is zero' do
          let(:job_args) { [group_id, { collection_window_lookback_days: 0 }] }

          it 'raises ArgumentError for invalid parameter' do
            expect do
              perform_export
            end.to raise_error(ArgumentError, 'collection_window_lookback_days must be a positive number')
          end
        end

        context 'when days_ago is negative' do
          let(:job_args) { [group_id, { collection_window_lookback_days: -1 }] }

          it 'raises ArgumentError for invalid parameter' do
            expect do
              perform_export
            end.to raise_error(ArgumentError, 'collection_window_lookback_days must be a positive number')
          end
        end

        context 'in production environment' do
          let(:job_args) { [group_id, { collection_window_lookback_days: 0 }] }

          before do
            stub_rails_env('production')
          end

          it_behaves_like 'does not enqueue any ExportWorker jobs'
        end
      end

      context 'when group has no projects' do
        let_it_be(:empty_group) { create(:group) }
        let(:group_id) { empty_group.id }

        it_behaves_like 'does not enqueue any ExportWorker jobs'
      end

      context 'when all projects are excluded due to descendant groups with observability settings' do
        let_it_be(:parent_group) { create(:group) }
        let_it_be(:excluded_subgroup) { create(:group, parent: parent_group) }
        let_it_be(:excluded_project) { create(:project, group: excluded_subgroup) }
        let_it_be(:excluded_pipeline) do
          create(:ci_pipeline, :success, project: excluded_project, created_at: 5.days.ago)
        end

        let_it_be(:group_o11y_setting) { create(:observability_group_o11y_setting, group: excluded_subgroup) }
        let(:group_id) { parent_group.id }

        it_behaves_like 'does not enqueue any ExportWorker jobs'
      end

      context 'when projects have no completed pipelines within the lookback window' do
        let_it_be(:test_group) { create(:group) }
        let_it_be(:project_no_pipelines) { create(:project, group: test_group) }
        let_it_be(:project_old_pipeline) { create(:project, group: test_group) }
        let_it_be(:old_pipeline) do
          create(:ci_pipeline, :success, project: project_old_pipeline, created_at: 15.days.ago)
        end

        let_it_be(:project_running_pipeline) { create(:project, group: test_group) }
        let_it_be(:running_pipeline) do
          create(:ci_pipeline, :running, project: project_running_pipeline, created_at: 5.days.ago)
        end

        let(:group_id) { test_group.id }

        it_behaves_like 'does not enqueue any ExportWorker jobs'
      end
    end
  end
end
