require 'rails_helper'

describe Clusters::Applications::Runner do
  let(:ci_runner) { create(:ci_runner) }

  include_examples 'cluster application core specs', :clusters_applications_runner
  include_examples 'cluster application status specs', :cluster_application_runner

  it { is_expected.to belong_to(:runner) }

  describe '#make_installing!' do
    before do
      application.make_installing!
    end

    context 'application install previously errored with older version' do
      let(:application) { create(:clusters_applications_runner, :scheduled, version: '0.1.30') }

      it 'updates the application version' do
        expect(application.reload.version).to eq('0.1.31')
      end
    end
  end

  describe '.installed' do
    subject { described_class.installed }

    let!(:cluster) { create(:clusters_applications_runner, :installed) }

    before do
      create(:clusters_applications_runner, :errored)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '#install_command' do
    let(:kubeclient) { double('kubernetes client') }
    let(:gitlab_runner) { create(:clusters_applications_runner, runner: ci_runner) }

    subject { gitlab_runner.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'should be initialized with 4 arguments' do
      expect(subject.name).to eq('runner')
      expect(subject.chart).to eq('runner/gitlab-runner')
      expect(subject.version).to eq('0.1.31')
      expect(subject).not_to be_rbac
      expect(subject.repository).to eq('https://charts.gitlab.io')
      expect(subject.files).to eq(gitlab_runner.files)
    end

    context 'on a rbac enabled cluster' do
      before do
        gitlab_runner.cluster.platform_kubernetes.rbac!
      end

      it { is_expected.to be_rbac }
    end

    context 'application failed to install previously' do
      let(:gitlab_runner) { create(:clusters_applications_runner, :errored, runner: ci_runner, version: '0.1.13') }

      it 'should be initialized with the locked version' do
        expect(subject.version).to eq('0.1.31')
      end
    end
  end

  describe '#files' do
    let(:application) { create(:clusters_applications_runner, runner: ci_runner) }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'should include cert files' do
      expect(subject[:'ca.pem']).to be_present
      expect(subject[:'ca.pem']).to eq(application.cluster.application_helm.ca_cert)

      expect(subject[:'cert.pem']).to be_present
      expect(subject[:'key.pem']).to be_present

      cert = OpenSSL::X509::Certificate.new(subject[:'cert.pem'])
      expect(cert.not_after).to be < 60.minutes.from_now
    end

    context 'when the helm application does not have a ca_cert' do
      before do
        application.cluster.application_helm.ca_cert = nil
      end

      it 'should not include cert files' do
        expect(subject[:'ca.pem']).not_to be_present
        expect(subject[:'cert.pem']).not_to be_present
        expect(subject[:'key.pem']).not_to be_present
      end
    end

    it 'should include runner valid values' do
      expect(values).to include('concurrent')
      expect(values).to include('checkInterval')
      expect(values).to include('rbac')
      expect(values).to include('runners')
      expect(values).to include('privileged: true')
      expect(values).to include('image: ubuntu:16.04')
      expect(values).to include('resources')
      expect(values).to match(/runnerToken: '?#{ci_runner.token}/)
      expect(values).to match(/gitlabUrl: '?#{Gitlab::Routing.url_helpers.root_url}/)
    end

    context 'without a runner' do
      let(:project) { create(:project) }
      let(:cluster) { create(:cluster, :with_installed_helm, projects: [project]) }
      let(:application) { create(:clusters_applications_runner, cluster: cluster) }

      it 'creates a runner' do
        expect do
          subject
        end.to change { Ci::Runner.count }.by(1)
      end

      it 'uses the new runner token' do
        expect(values).to match(/runnerToken: '?#{application.reload.runner.token}/)
      end

      it 'assigns the new runner to runner' do
        subject

        expect(application.reload.runner).to be_project_type
      end
    end

    context 'with duplicated values on vendor/runner/values.yaml' do
      let(:stub_values) do
        {
          "concurrent" => 4,
          "checkInterval" => 3,
          "rbac" => {
            "create" => false
          },
          "clusterWideAccess" => false,
          "runners" => {
            "privileged" => false,
            "image" => "ubuntu:16.04",
            "builds" => {},
            "services" => {},
            "helpers" => {}
          }
        }
      end

      before do
        allow(application).to receive(:chart_values).and_return(stub_values)
      end

      it 'should overwrite values.yaml' do
        expect(values).to match(/privileged: '?#{application.privileged}/)
      end
    end
  end
end
