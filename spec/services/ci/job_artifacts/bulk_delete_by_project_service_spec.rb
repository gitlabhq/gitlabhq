# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::JobArtifacts::BulkDeleteByProjectService, "#execute", feature_category: :job_artifacts do
  subject(:execute) do
    described_class.new(
      job_artifact_ids: job_artifact_ids,
      current_user: current_user,
      project: project).execute
  end

  let_it_be(:current_user) { create(:user) }
  let_it_be(:build, reload: true) do
    create(:ci_build, :artifacts, :trace_artifact, user: current_user)
  end

  let_it_be(:project) { build.project }
  let_it_be(:job_artifact_ids) { build.job_artifacts.map(&:id) }

  describe '#execute' do
    context 'when number of artifacts exceeds limits to delete' do
      let_it_be(:second_build, reload: true) do
        create(:ci_build, :artifacts, :trace_artifact, user: current_user, project: project)
      end

      let_it_be(:job_artifact_ids) { ::Ci::JobArtifact.all.map(&:id) }

      before do
        project.add_maintainer(current_user)
        stub_const("#{described_class}::JOB_ARTIFACTS_COUNT_LIMIT", 1)
      end

      it 'fails to destroy' do
        result = execute

        expect(result).to be_error
        expect(result[:message]).to eq('Can only delete up to 1 job artifacts per call')
      end
    end

    context 'when requested not existing artifacts do delete' do
      let_it_be(:deleted_build, reload: true) do
        create(:ci_build, :artifacts, :trace_artifact, user: current_user, project: project)
      end

      let_it_be(:deleted_job_artifacts) { deleted_build.job_artifacts }
      let_it_be(:job_artifact_ids) { ::Ci::JobArtifact.all.map(&:id) }

      before do
        project.add_maintainer(current_user)
        deleted_job_artifacts.each(&:destroy!)
      end

      it 'fails to destroy' do
        result = execute

        expect(result).to be_error

        expected_ids = deleted_job_artifacts.map(&:id).sort
        result_ids = result[:message].scan(/\d+/).map(&:to_i).sort

        expect(result_ids).to eq(expected_ids)
        expect(result[:message]).to match(/Artifacts \(\d+,\d+,\d+\) not found/)
      end
    end

    context 'when maintainer has access to the project' do
      before do
        project.add_maintainer(current_user)
      end

      it 'is successful' do
        result = execute

        expect(result).to be_success
        expect(result.payload[:destroyed_ids]).to match_array(job_artifact_ids)
        expect(result.payload.except(:destroyed_ids)).to eq(
          {
            destroyed_count: job_artifact_ids.count,
            errors: []
          }
        )
        expect(::Ci::JobArtifact.where(id: job_artifact_ids).count).to eq(0)
      end

      context 'and partially owns artifacts' do
        let_it_be(:orphan_artifact) { create(:ci_job_artifact, :archive) }
        let_it_be(:orphan_artifact_id) { orphan_artifact.id }
        let_it_be(:owned_artifacts_ids) { build.job_artifacts.erasable.map(&:id) }
        let_it_be(:job_artifact_ids) { [orphan_artifact_id] + owned_artifacts_ids }

        it 'fails to destroy' do
          result = execute

          expect(result).to be_error
          expect(result[:message]).to be('Not all artifacts belong to requested project')
          expect(::Ci::JobArtifact.where(id: job_artifact_ids).count).to eq(3)
        end
      end

      context 'and request all artifacts from a different project' do
        let_it_be(:different_project_artifact) { create(:ci_job_artifact, :archive) }
        let_it_be(:job_artifact_ids) { [different_project_artifact] }

        let_it_be(:different_build, reload: true) do
          create(:ci_build, :artifacts, :trace_artifact, user: current_user)
        end

        let_it_be(:different_project) { different_build.project }

        before do
          different_project.add_maintainer(current_user)
        end

        it 'returns a error' do
          result = execute

          expect(result).to be_error
          expect(result[:message]).to be('Not all artifacts belong to requested project')
          expect(::Ci::JobArtifact.where(id: job_artifact_ids).count).to eq(job_artifact_ids.count)
        end
      end
    end
  end
end
