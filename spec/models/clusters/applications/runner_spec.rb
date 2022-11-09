# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::Runner do
  let(:ci_runner) { create(:ci_runner) }

  include_examples 'cluster application core specs', :clusters_applications_runner
  include_examples 'cluster application status specs', :clusters_applications_runner
  include_examples 'cluster application version specs', :clusters_applications_runner
  include_examples 'cluster application helm specs', :clusters_applications_runner
  include_examples 'cluster application initial status specs'

  it { is_expected.to belong_to(:runner) }

  describe 'default values' do
    it { expect(subject.version).to eq(described_class::VERSION) }
  end

  describe '#can_uninstall?' do
    let(:gitlab_runner) { create(:clusters_applications_runner, runner: ci_runner) }

    subject { gitlab_runner.can_uninstall? }

    it { is_expected.to be_truthy }
  end

  describe '#install_command' do
    let(:kubeclient) { double('kubernetes client') }
    let(:gitlab_runner) { create(:clusters_applications_runner, runner: ci_runner) }

    subject { gitlab_runner.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::V3::InstallCommand) }

    it 'is initialized with 4 arguments' do
      expect(subject.name).to eq('runner')
      expect(subject.chart).to eq('runner/gitlab-runner')
      expect(subject.version).to eq(Clusters::Applications::Runner::VERSION)
      expect(subject).to be_rbac
      expect(subject.repository).to eq('https://charts.gitlab.io')
      expect(subject.files).to eq(gitlab_runner.files)
    end

    context 'on a non rbac enabled cluster' do
      before do
        gitlab_runner.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end

    context 'application failed to install previously' do
      let(:gitlab_runner) { create(:clusters_applications_runner, :errored, runner: ci_runner, version: '0.1.13') }

      it 'is initialized with the locked version' do
        expect(subject.version).to eq(Clusters::Applications::Runner::VERSION)
      end
    end
  end

  describe '#files' do
    let(:application) { create(:clusters_applications_runner, runner: ci_runner) }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'includes runner valid values' do
      expect(values).to include('concurrent')
      expect(values).to include('checkInterval')
      expect(values).to include('rbac')
      expect(values).to include('runners')
      expect(values).to include('privileged: true')
      expect(values).to include('image: ubuntu:16.04')
      expect(values).to include('resources')
      expect(values).to match(/gitlabUrl: ['"]?#{Regexp.escape(Gitlab::Routing.url_helpers.root_url)}/)
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

      it 'overwrites values.yaml' do
        expect(values).to match(/privileged: '?#{application.privileged}/)
      end
    end
  end

  describe '#make_uninstalling!' do
    subject { create(:clusters_applications_runner, :scheduled, runner: ci_runner) }

    it 'calls prepare_uninstall' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:prepare_uninstall).and_call_original
      end

      subject.make_uninstalling!
    end
  end

  describe '#post_uninstall' do
    it 'destroys its runner' do
      application_runner = create(:clusters_applications_runner, :scheduled, runner: ci_runner)

      expect { application_runner.post_uninstall }.to change { Ci::Runner.count }.by(-1)
    end
  end
end
