# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CodeNavigationPath, feature_category: :source_code_management do
  context 'when there is an artifact with code navigation data' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:sha) { project.repository.commits('master', limit: Gitlab::CodeNavigationPath::LATEST_COMMITS_LIMIT).last.id }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, sha: sha) }
    let_it_be(:job) { create(:ci_build, pipeline: pipeline) }
    let_it_be(:artifact) { create(:ci_job_artifact, :lsif, job: job) }

    let(:commit_sha) { sha }
    let(:path) { 'lib/app.rb' }
    let(:lsif_path) { "/#{project.full_path}/-/jobs/#{job.id}/artifacts/raw/lsif/#{path}.json?file_type=lsif" }

    subject { described_class.new(project, commit_sha).full_json_path_for(path) }

    context 'when project does not have a lsif artifact' do
      let_it_be(:project) { create(:project, :empty_repo) }

      it { is_expected.to be_nil }
    end

    context 'when a pipeline exist for a sha' do
      it 'returns path to a file in the artifact' do
        expect(subject).to eq(lsif_path)
      end

      context 'when passed commit sha is nil' do
        let(:commit_sha) { nil }

        it 'returns path to a file in the artifact' do
          expect(subject).to eq(lsif_path)
        end
      end
    end

    context 'when a pipeline exist for the latest commits' do
      let(:commit_sha) { project.commit.id }

      it 'returns path to a file in the artifact' do
        expect(subject).to eq(lsif_path)
      end
    end

    context 'when artifact loading takes too long' do
      before do
        allow(Timeout).to receive(:timeout).with(described_class::ARTIFACT_TIMEOUT).and_raise(Timeout::Error)
      end

      it { is_expected.to be_nil }
    end
  end
end
