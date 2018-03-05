require 'rails_helper'

describe Clusters::Applications::Runner do
  let(:ci_runner) { create(:ci_runner) }

  include_examples 'cluster application core specs', :clusters_applications_runner
  include_examples 'cluster application status specs', :cluster_application_runner

  it { is_expected.to belong_to(:runner) }

  describe '#install_command' do
    let(:kubeclient) { double('kubernetes client') }
    let(:gitlab_runner) { create(:clusters_applications_runner, runner: ci_runner) }

    subject { gitlab_runner.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'should be initialized with 4 arguments' do
      expect(subject.name).to eq('runner')
      expect(subject.chart).to eq('runner/gitlab-runner')
      expect(subject.repository).to eq('https://charts.gitlab.io')
      expect(subject.values).to eq(gitlab_runner.values)
    end
  end

  describe '#values' do
    let(:gitlab_runner) { create(:clusters_applications_runner, runner: ci_runner) }

    subject { gitlab_runner.values }

    it 'should include runner valid values' do
      is_expected.to include('concurrent')
      is_expected.to include('checkInterval')
      is_expected.to include('rbac')
      is_expected.to include('runners')
      is_expected.to include('resources')
      is_expected.to include("runnerToken: #{ci_runner.token}")
      is_expected.to include("gitlabUrl: #{Gitlab::Routing.url_helpers.root_url}")
    end

    context 'without a runner' do
      let(:project) { create(:project) }
      let(:cluster) { create(:cluster, projects: [project]) }
      let(:gitlab_runner) { create(:clusters_applications_runner, cluster: cluster) }

      it 'creates a runner' do
        expect do
          subject
        end.to change { Ci::Runner.count }.by(1)
      end

      it 'uses the new runner token' do
        expect(subject).to include("runnerToken: #{gitlab_runner.reload.runner.token}")
      end

      it 'assigns the new runner to runner' do
        subject
        gitlab_runner.reload

        expect(gitlab_runner.runner).not_to be_nil
      end
    end
  end
end
