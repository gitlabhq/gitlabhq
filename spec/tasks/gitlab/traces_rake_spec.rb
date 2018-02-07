require 'rake_helper'

describe 'gitlab:traces namespace rake task' do
  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/traces'
  end

  subject { run_rake_task('gitlab:traces:migrate', relative_path) }

  context 'when relative path points root' do
    let(:relative_path) { '.' }

    let!(:job1) { create(:ci_build, :trace_live, :success) }
    let!(:job2) { create(:ci_build, :trace_artifact, :success) }

    it 'migrates' do
      expect { subject }.to change { Ci::JobArtifact.count }.by(1)

      expect(job1.job_artifacts_trace).not_to be_nil
    end
  end
end
