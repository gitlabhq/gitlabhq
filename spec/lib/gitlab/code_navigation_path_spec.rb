# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CodeNavigationPath do
  context 'when there is an artifact with code navigation data' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:sha) { project.repository.commits('master', limit: 5).last.id }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, sha: sha) }
    let_it_be(:job) { create(:ci_build, pipeline: pipeline) }
    let_it_be(:artifact) { create(:ci_job_artifact, :lsif, job: job) }

    let(:commit_sha) { sha }
    let(:path) { 'lib/app.rb' }

    subject { described_class.new(project, commit_sha).full_json_path_for(path) }

    before do
      stub_feature_flags(code_navigation: project)
    end

    context 'when a pipeline exist for a sha' do
      it 'returns path to a file in the artifact' do
        expect(subject).to eq("/#{project.full_path}/-/jobs/#{job.id}/artifacts/raw/lsif/#{path}.json?file_type=lsif")
      end
    end

    context 'when a pipeline exist for the latest commits' do
      let(:commit_sha) { project.commit.id }

      it 'returns path to a file in the artifact' do
        expect(subject).to eq("/#{project.full_path}/-/jobs/#{job.id}/artifacts/raw/lsif/#{path}.json?file_type=lsif")
      end
    end

    context 'when code_navigation feature is disabled' do
      before do
        stub_feature_flags(code_navigation: false)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
