# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CodeNavigationPath do
  context 'when there is an artifact with code navigation data' do
    let(:project) { create(:project, :repository) }
    let(:sha) { project.commit.id }
    let(:build_name) { Gitlab::CodeNavigationPath::CODE_NAVIGATION_JOB_NAME }
    let(:path) { 'lib/app.rb' }
    let!(:pipeline) { create(:ci_pipeline, project: project, sha: sha) }
    let!(:job) { create(:ci_build, pipeline: pipeline, name: build_name) }
    let!(:artifact) { create(:ci_job_artifact, :lsif, job: job) }

    subject { described_class.new(project, sha).full_json_path_for(path) }

    it 'assigns code_navigation_build variable' do
      expect(subject).to eq("/#{project.full_path}/-/jobs/#{job.id}/artifacts/raw/lsif/#{path}.json")
    end

    context 'when code_navigation feature is disabled' do
      before do
        stub_feature_flags(code_navigation: false)
      end

      it 'does not assign code_navigation_build variable' do
        expect(subject).to be_nil
      end
    end
  end
end
