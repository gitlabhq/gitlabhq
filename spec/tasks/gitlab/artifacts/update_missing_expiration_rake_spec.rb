# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:artifacts rake tasks', feature_category: :job_artifacts do
  describe 'update_missing_expiration' do
    before do
      Rake.application.rake_require('tasks/gitlab/artifacts/update_missing_expiration')
    end

    # rubocop:disable RSpec/AvoidTestProf -- group and project are created only once.
    let_it_be(:group) { create(:group) }

    let_it_be(:project_1) { create(:project, :repository, group: group) }

    let_it_be(:project_2) { create(:project, :repository, group: group) }
    # rubocop:enable RSpec/AvoidTestProf -- group and project are created only once.

    let(:pipeline_1) do
      create(
        :ci_pipeline,
        project: project_1,
        sha: project_1.commit.id,
        ref: project_1.default_branch,
        status: 'success'
      )
    end

    let(:pipeline_2) do
      create(
        :ci_pipeline,
        project: project_2,
        sha: project_2.commit.id,
        ref: project_2.default_branch,
        status: 'success'
      )
    end

    let(:build_1) { create(:ci_build, pipeline: pipeline_1, artifacts_expire_at: nil) }
    let!(:artifact_1) { create(:ci_job_artifact, job: build_1, project: build_1.project, expire_at: nil) }
    let(:build_2) { create(:ci_build, pipeline: pipeline_2, artifacts_expire_at: nil) }
    let!(:artifact_2) { create(:ci_job_artifact, job: build_2, project: build_2.project, expire_at: nil) }

    it 'raises an error when arguments are not provided' do
      expect { run_rake_task('gitlab:artifacts:update_missing_expiration') }.to raise_error(SystemExit)
    end

    context 'when PROJECT_PATH is provided' do
      before do
        stub_env('PROJECT_PATH', project_1.full_path)
      end

      it 'does not raise an error' do
        expect { run_rake_task('gitlab:artifacts:update_missing_expiration') }.not_to raise_error
      end

      it 'raises an error when invalid project path' do
        stub_env('PROJECT_PATH', 'invalid_project_path')
        expect { run_rake_task('gitlab:artifacts:update_missing_expiration') }.to raise_error(SystemExit)
      end

      context 'when DRY_RUN is true' do
        it 'does not update artifacts' do
          expect { run_rake_task('gitlab:artifacts:update_missing_expiration') }
            .to not_change { build_1.reload.artifacts_expire_at }
            .and not_change { artifact_1.reload.expire_at }
        end
      end

      context 'when DRY_RUN is false' do
        before do
          stub_env('DRY_RUN', 'false')
        end

        it 'updates artifacts' do
          expect { run_rake_task('gitlab:artifacts:update_missing_expiration') }
            .to change { build_1.reload.artifacts_expire_at }
            .and change { artifact_1.reload.expire_at }
        end
      end
    end

    context 'when GROUP_PATH is provided' do
      before do
        stub_env('GROUP_PATH', group.full_path)
      end

      it 'raises an error when invalid group path' do
        stub_env('GROUP_PATH', 'invalid_group_path')
        expect { run_rake_task('gitlab:artifacts:update_missing_expiration') }.to raise_error(SystemExit)
      end

      it 'does not raise an error' do
        expect { run_rake_task('gitlab:artifacts:update_missing_expiration') }.not_to raise_error
      end

      context 'when DRY_RUN is true' do
        it 'does not update artifacts' do
          expect { run_rake_task('gitlab:artifacts:update_missing_expiration') }
            .to not_change { build_1.reload.artifacts_expire_at }
            .and not_change { artifact_1.reload.expire_at }
            .and not_change { build_2.reload.artifacts_expire_at }
            .and not_change { artifact_2.reload.expire_at }
        end
      end

      context 'when DRY_RUN is false' do
        before do
          stub_env('DRY_RUN', 'false')
        end

        it 'updates artifacts' do
          expect { run_rake_task('gitlab:artifacts:update_missing_expiration') }
            .to change { build_1.reload.artifacts_expire_at }
            .and change { artifact_1.reload.expire_at }
            .and change { build_2.reload.artifacts_expire_at }
            .and change { artifact_2.reload.expire_at }
        end
      end
    end
  end
end
