# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineEntity, feature_category: :continuous_integration do
  include Gitlab::Routing

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_empty_pipeline, name: 'Build pipeline') }

  let(:request) { double('request', current_user: user) }
  let(:options) { {} }
  let(:entity) { described_class.represent(pipeline, request: request, **options) }

  describe '#as_json' do
    subject { entity.as_json }

    context 'when pipeline is empty' do
      it 'contains required fields' do
        expect(subject).to include :id, :iid, :user, :path, :coverage, :source
        expect(subject).to include :ref, :commit
        expect(subject).to include :updated_at, :created_at
        expect(subject[:name]).to eq('Build pipeline')
      end

      it 'excludes coverage data when disabled' do
        entity = described_class
          .represent(pipeline, request: request, disable_coverage: true)

        expect(entity.as_json).not_to include(:coverage)
      end

      it 'contains details' do
        allow(pipeline).to receive(:merge_request_event_type).and_return(:merged_result)

        expect(subject).to include :details
        expect(subject[:details])
          .to include :duration, :finished_at, :event_type_name
        expect(subject[:details][:status]).to include :icon, :favicon, :text, :label, :tooltip

        expect(subject[:details][:event_type_name]).to eq('Merged results pipeline')
      end

      it 'contains flags' do
        expect(subject).to include(:flags)
        expect(subject[:flags]).to include(
          :stuck, :auto_devops, :yaml_errors, :retryable, :cancelable, :merge_request
        )
      end
    end

    context 'when default branch not protected' do
      before do
        stub_not_protect_default_branch
      end

      context 'when pipeline is retryable' do
        let_it_be(:pipeline) do
          create(:ci_pipeline, status: :success, project: project)
        end

        before do
          create(:ci_build, :failed, pipeline: pipeline)
        end

        it 'does not serialize stage builds' do
          subject.with_indifferent_access.dig(:details, :stages, 0).tap do |stage|
            expect(stage).not_to include(:groups, :latest_statuses, :retries)
          end
        end

        context 'user has ability to retry pipeline' do
          before do
            project.add_developer(user)
          end

          it 'contains retry path' do
            expect(subject[:retry_path]).to be_present
          end
        end

        context 'user does not have ability to retry pipeline' do
          it 'does not contain retry path' do
            expect(subject).not_to have_key(:retry_path)
          end
        end
      end

      context 'when pipeline is cancelable' do
        let_it_be(:pipeline) do
          create(:ci_pipeline, status: :running, project: project)
        end

        before do
          create(:ci_build, :pending, pipeline: pipeline)
        end

        it 'does not serialize stage builds' do
          subject.with_indifferent_access.dig(:details, :stages, 0).tap do |stage|
            expect(stage).not_to include(:groups, :latest_statuses, :retries)
          end
        end

        context 'user has ability to cancel pipeline' do
          before do
            project.add_developer(user)
          end

          it 'contains cancel path' do
            expect(subject[:cancel_path]).to be_present
          end
        end

        context 'user does not have ability to cancel pipeline' do
          it 'does not contain cancel path' do
            expect(subject).not_to have_key(:cancel_path)
          end
        end
      end
    end

    context 'delete path' do
      context 'user has ability to delete pipeline' do
        let(:project) { create(:project, namespace: user.namespace) }
        let(:pipeline) { create(:ci_pipeline, project: project) }

        it 'contains delete path' do
          expect(subject[:delete_path]).to be_present
        end
      end

      context 'user does not have ability to delete pipeline' do
        let(:pipeline) { create(:ci_pipeline, project: project) }

        it 'does not contain delete path' do
          expect(subject).not_to have_key(:delete_path)
        end
      end
    end

    context 'when pipeline ref is empty' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      before do
        allow(pipeline).to receive(:ref).and_return(nil)
      end

      it 'does not generate branch path' do
        expect(subject[:ref][:path]).to be_nil
      end
    end

    context 'when pipeline has a failure reason set' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      before do
        pipeline.drop!(:config_error)
      end

      it 'has a correct failure reason' do
        expect(subject[:failure_reason])
          .to eq 'The pipeline failed due to an error on the CI/CD configuration file.'
      end
    end

    context 'when request has a project' do
      before do
        allow(request).to receive(:project).and_return(project)
      end

      context 'when pipeline is detached merge request pipeline' do
        let_it_be(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }

        let(:project) { merge_request.target_project }
        let(:pipeline) { merge_request.pipelines_for_merge_request.first }

        it 'makes detached flag true' do
          expect(subject[:flags][:detached_merge_request_pipeline]).to be_truthy
        end

        it 'does not expose source sha and target sha' do
          expect(subject[:source_sha]).to be_nil
          expect(subject[:target_sha]).to be_nil
        end

        context 'when user is a developer' do
          before do
            project.add_developer(user)
          end

          it 'has merge request information' do
            expect(subject[:merge_request][:iid]).to eq(merge_request.iid)

            expect(project_merge_request_path(project, merge_request))
              .to include(subject[:merge_request][:path])

            expect(subject[:merge_request][:title]).to eq(merge_request.title)

            expect(subject[:merge_request][:source_branch])
              .to eq(merge_request.source_branch)

            expect(project_commits_path(project, merge_request.source_branch))
              .to include(subject[:merge_request][:source_branch_path])

            expect(subject[:merge_request][:target_branch])
              .to eq(merge_request.target_branch)

            expect(project_commits_path(project, merge_request.target_branch))
              .to include(subject[:merge_request][:target_branch_path])
          end
        end

        context 'when user is an external user' do
          it 'has no merge request information' do
            expect(subject[:merge_request]).to be_nil
          end
        end
      end

      context 'when pipeline is merge request pipeline' do
        let_it_be(:merge_request) { create(:merge_request, :with_merge_request_pipeline, merge_sha: 'abc') }

        let(:project) { merge_request.target_project }
        let(:pipeline) { merge_request.pipelines_for_merge_request.first }

        it 'makes detached flag false' do
          expect(subject[:flags][:detached_merge_request_pipeline]).to be_falsy
        end

        it 'makes atached flag true' do
          expect(subject[:flags][:merge_request_pipeline]).to be true
          expect(subject[:flags][:merge_request]).to be true
        end

        it 'exposes source sha and target sha' do
          expect(subject[:source_sha]).to be_present
          expect(subject[:target_sha]).to be_present
        end

        it 'exposes merge request event type' do
          expect(subject[:merge_request_event_type]).to be_present
        end
      end
    end

    context 'when pipeline has failed builds' do
      let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }
      let_it_be(:build) { create(:ci_build, :success, pipeline: pipeline) }
      let_it_be(:failed_1) { create(:ci_build, :failed, pipeline: pipeline) }
      let_it_be(:failed_2) { create(:ci_build, :failed, pipeline: pipeline) }

      context 'when the user can retry the pipeline' do
        before do
          project.add_maintainer(user)
        end

        context 'when disable_failed_builds is true' do
          let(:options) { { disable_failed_builds: true } }

          it 'exposes the failed builds count but not the failed builds' do
            expect(subject[:failed_builds_count]).to eq(2)
            expect(subject).not_to have_key(:failed_builds)
          end

          context 'when over the limit' do
            before do
              stub_const('Ci::Pipeline::COUNT_FAILED_JOBS_LIMIT', 1)
              pipeline.reload # reload the pipeline with the mocked constant code
            end

            it 'uses the limited scope and limits the return value' do
              expect(subject[:failed_builds_count]).to eq(1)
              expect(subject).not_to have_key(:failed_builds)
            end
          end
        end

        context 'when disable_failed_builds is false' do
          let(:options) { { disable_failed_builds: false } }

          it 'exposes the failed builds count but not the failed builds' do
            expect(subject[:failed_builds_count]).to eq(2)
            expect(subject[:failed_builds].map { |b| b[:id] }).to contain_exactly(failed_1.id, failed_2.id)
          end

          context 'when over the limit' do
            before do
              stub_const('Ci::Pipeline::COUNT_FAILED_JOBS_LIMIT', 1)
              pipeline.reload
            end

            it 'uses the unlimited scope' do
              expect(subject[:failed_builds_count]).to eq(2)
              expect(subject).to have_key(:failed_builds)
            end
          end
        end

        context 'when disable_failed_builds is nil' do
          it 'exposes the failed builds count and the failed builds' do
            expect(subject[:failed_builds_count]).to eq(2)
            expect(subject[:failed_builds].map { |b| b[:id] }).to contain_exactly(failed_1.id, failed_2.id)
          end
        end
      end

      context 'when the user cannot retry the pipeline' do
        it 'is nil' do
          expect(subject[:failed_builds]).to be_nil
        end
      end
    end

    context 'when pipeline has coverage' do
      let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }

      before do
        allow(pipeline).to receive(:coverage).and_return(35.0)
      end

      it 'exposes the coverage' do
        expect(subject[:coverage]).to eq('35.00')
      end
    end

    context 'when pipeline has a schedule' do
      let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly, project: project) }
      let_it_be(:pipeline) { create(:ci_pipeline, pipeline_schedule: pipeline_schedule, project: project) }

      it 'exposes the schedule' do
        expect(subject[:pipeline_schedule]).to eq({
          id: pipeline_schedule.id,
          description: pipeline_schedule.description,
          path: pipeline_schedules_path(pipeline_schedule.project)
        })
      end
    end

    context 'when pipeline has no schedule' do
      let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

      it 'is nil' do
        expect(subject[:pipeline_schedule]).to be_nil
      end
    end
  end
end
