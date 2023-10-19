# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::ExperimentTracking::HandleCandidateGitlabMetadataService, feature_category: :activation do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build) { create(:ci_build, :success, pipeline: pipeline) }

  let(:metadata) { [] }
  let(:candidate) { create(:ml_candidates, project: project, user: user) }

  describe 'execute' do
    subject { described_class.new(candidate, metadata).execute }

    context 'when metadata includes gitlab.CI_JOB_ID', 'and gitlab.CI_JOB_ID is valid' do
      let(:metadata) do
        [
          { key: 'gitlab.CI_JOB_ID', value: build.id.to_s }
        ]
      end

      it 'updates candidate correctly', :aggregate_failures do
        subject

        expect(candidate.ci_build).to eq(build)
      end
    end

    context 'when metadata includes gitlab.CI_JOB_ID and gitlab.CI_JOB_ID is invalid' do
      let(:metadata) { [{ key: 'gitlab.CI_JOB_ID', value: non_existing_record_id.to_s }] }

      it 'raises error' do
        expect { subject }
          .to raise_error(ArgumentError, 'gitlab.CI_JOB_ID must refer to an existing build')
      end
    end
  end
end
