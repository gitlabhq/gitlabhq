# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jobs/Deploy.gitlab-ci.yml' do
  subject(:template) do
    <<~YAML
      stages:
        - test
        - review
        - staging
        - canary
        - production
        - incremental rollout 10%
        - incremental rollout 25%
        - incremental rollout 50%
        - incremental rollout 100%
        - cleanup

      include:
        - template: Jobs/Deploy.gitlab-ci.yml

      placeholder:
        script:
          - echo "Ensure at least one job to keep pipeline validator happy"
    YAML
  end

  describe 'the created pipeline' do
    let(:project) { create(:project, :repository) }
    let(:user) { project.owner }

    let(:default_branch) { 'master' }
    let(:pipeline_ref) { default_branch }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_ref) }
    let(:pipeline) { service.execute!(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template)

      allow_any_instance_of(Ci::BuildScheduleWorker).to receive(:perform).and_return(true)
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'with no cluster' do
      it 'does not create any kubernetes deployment jobs' do
        expect(build_names).to eq %w(placeholder)
      end
    end

    context 'with only a disabled cluster' do
      let!(:cluster) { create(:cluster, :project, :provided_by_gcp, enabled: false, projects: [project]) }

      it 'does not create any kubernetes deployment jobs' do
        expect(build_names).to eq %w(placeholder)
      end
    end

    context 'with an active cluster' do
      let!(:cluster) { create(:cluster, :project, :provided_by_gcp, projects: [project]) }

      context 'on master' do
        it 'by default' do
          expect(build_names).to include('production')
          expect(build_names).not_to include('review')
        end

        it 'when CANARY_ENABLED' do
          create(:ci_variable, project: project, key: 'CANARY_ENABLED', value: 'true')

          expect(build_names).to include('production_manual')
          expect(build_names).to include('canary')
          expect(build_names).not_to include('production')
        end

        it 'when STAGING_ENABLED' do
          create(:ci_variable, project: project, key: 'STAGING_ENABLED', value: 'true')

          expect(build_names).to include('production_manual')
          expect(build_names).to include('staging')
          expect(build_names).not_to include('production')
        end

        it 'when INCREMENTAL_ROLLOUT_MODE == timed' do
          create(:ci_variable, project: project, key: 'INCREMENTAL_ROLLOUT_ENABLED', value: 'true')
          create(:ci_variable, project: project, key: 'INCREMENTAL_ROLLOUT_MODE', value: 'timed')

          expect(build_names).not_to include('production_manual')
          expect(build_names).not_to include('production')
          expect(build_names).not_to include(
            'rollout 10%',
            'rollout 25%',
            'rollout 50%',
            'rollout 100%'
          )
          expect(build_names).to include(
            'timed rollout 10%',
            'timed rollout 25%',
            'timed rollout 50%',
            'timed rollout 100%'
          )
        end

        it 'when INCREMENTAL_ROLLOUT_ENABLED' do
          create(:ci_variable, project: project, key: 'INCREMENTAL_ROLLOUT_ENABLED', value: 'true')

          expect(build_names).not_to include('production_manual')
          expect(build_names).not_to include('production')
          expect(build_names).not_to include(
            'timed rollout 10%',
            'timed rollout 25%',
            'timed rollout 50%',
            'timed rollout 100%'
          )
          expect(build_names).to include(
            'rollout 10%',
            'rollout 25%',
            'rollout 50%',
            'rollout 100%'
          )
        end

        it 'when INCREMENTAL_ROLLOUT_MODE == manual' do
          create(:ci_variable, project: project, key: 'INCREMENTAL_ROLLOUT_MODE', value: 'manual')

          expect(build_names).not_to include('production_manual')
          expect(build_names).not_to include('production')
          expect(build_names).not_to include(
            'timed rollout 10%',
            'timed rollout 25%',
            'timed rollout 50%',
            'timed rollout 100%'
          )
          expect(build_names).to include(
            'rollout 10%',
            'rollout 25%',
            'rollout 50%',
            'rollout 100%'
          )
        end
      end

      shared_examples_for 'review app deployment' do
        it 'creates the review and stop_review jobs but no production jobs' do
          expect(build_names).to include('review')
          expect(build_names).to include('stop_review')
          expect(build_names).not_to include('production')
          expect(build_names).not_to include('production_manual')
          expect(build_names).not_to include('staging')
          expect(build_names).not_to include('canary')
          expect(build_names).not_to include('timed rollout 10%')
          expect(build_names).not_to include('timed rollout 25%')
          expect(build_names).not_to include('timed rollout 50%')
          expect(build_names).not_to include('timed rollout 100%')
          expect(build_names).not_to include('rollout 10%')
          expect(build_names).not_to include('rollout 25%')
          expect(build_names).not_to include('rollout 50%')
          expect(build_names).not_to include('rollout 100%')
        end

        it 'does not include review when REVIEW_DISABLED' do
          create(:ci_variable, project: project, key: 'REVIEW_DISABLED', value: 'true')

          expect(build_names).not_to include('review')
          expect(build_names).not_to include('stop_review')
        end
      end

      context 'on branch' do
        let(:pipeline_ref) { 'feature' }

        before do
          allow_any_instance_of(Gitlab::Ci::Pipeline::Chain::Validate::Repository).to receive(:perform!).and_return(true)
        end

        it_behaves_like 'review app deployment'

        context 'when INCREMENTAL_ROLLOUT_ENABLED' do
          before do
            create(:ci_variable, project: project, key: 'INCREMENTAL_ROLLOUT_ENABLED', value: 'true')
          end

          it_behaves_like 'review app deployment'
        end

        context 'when INCREMENTAL_ROLLOUT_MODE == "timed"' do
          before do
            create(:ci_variable, project: project, key: 'INCREMENTAL_ROLLOUT_MODE', value: 'timed')
          end

          it_behaves_like 'review app deployment'
        end

        context 'when INCREMENTAL_ROLLOUT_MODE == "manual"' do
          before do
            create(:ci_variable, project: project, key: 'INCREMENTAL_ROLLOUT_MODE', value: 'manual')
          end

          it_behaves_like 'review app deployment'
        end
      end

      context 'on tag' do
        let(:pipeline_ref) { 'v1.0.0' }

        it_behaves_like 'review app deployment'
      end

      context 'on merge request' do
        let(:service) { MergeRequests::CreatePipelineService.new(project: project, current_user: user) }
        let(:merge_request) { create(:merge_request, :simple, source_project: project) }
        let(:pipeline) { service.execute(merge_request).payload }

        it 'has no jobs' do
          expect(pipeline).to be_merge_request_event
          expect(build_names).to be_empty
        end
      end
    end
  end
end
