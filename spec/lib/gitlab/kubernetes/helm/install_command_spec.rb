require 'rails_helper'

describe Gitlab::Kubernetes::Helm::InstallCommand do
  let(:prometheus) { create(:clusters_applications_prometheus) }

  describe "#initialize" do
    context "With all the params" do
      subject { described_class.new(prometheus.name, install_helm: true, chart: prometheus.chart, chart_values_file: prometheus.chart_values_file) }

      it 'should assign all parameters' do
        expect(subject.name).to eq(prometheus.name)
        expect(subject.install_helm).to be_truthy
        expect(subject.chart).to eq(prometheus.chart)
        expect(subject.chart_values_file).to eq("#{Rails.root}/vendor/prometheus/values.yaml")
      end
    end

    context 'when install_helm is not set' do
      subject { described_class.new(prometheus.name, chart: prometheus.chart, chart_values_file: true) }

      it 'should set install_helm as false' do
        expect(subject.install_helm).to be_falsy
      end
    end

    context 'when chart is not set' do
      subject { described_class.new(prometheus.name, install_helm: true) }

      it 'should set chart as nil' do
        expect(subject.chart).to be_falsy
      end
    end

    context 'when chart_values_file is not set' do
      subject { described_class.new(prometheus.name, install_helm: true, chart: prometheus.chart) }

      it 'should set chart_values_file as nil' do
        expect(subject.chart_values_file).to be_falsy
      end
    end
  end

  describe "#generate_script" do
    let(:install_command) { described_class.new(prometheus.name, install_helm: install_helm) }
    let(:client) { double('kubernetes client') }
    let(:namespace) { Gitlab::Kubernetes::Namespace.new(Gitlab::Kubernetes::Helm::NAMESPACE, client) }
    subject { install_command.send(:generate_script, namespace.name) }

    context 'when install helm is true' do
      let(:install_helm) { true }
      let(:command) do
        <<~MSG
        set -eo pipefail
        apk add -U ca-certificates openssl >/dev/null
        wget -q -O - https://kubernetes-helm.storage.googleapis.com/helm-v2.7.0-linux-amd64.tar.gz | tar zxC /tmp >/dev/null
        mv /tmp/linux-amd64/helm /usr/bin/

        helm init >/dev/null
        MSG
      end

      it 'should return appropriate command' do
        is_expected.to eq(command)
      end
    end

    context 'when install helm is false' do
      let(:install_helm) { false }
      let(:command) do
        <<~MSG
        set -eo pipefail
        apk add -U ca-certificates openssl >/dev/null
        wget -q -O - https://kubernetes-helm.storage.googleapis.com/helm-v2.7.0-linux-amd64.tar.gz | tar zxC /tmp >/dev/null
        mv /tmp/linux-amd64/helm /usr/bin/

        helm init --client-only >/dev/null
        MSG
      end

      it 'should return appropriate command' do
        is_expected.to eq(command)
      end
    end

    context 'when chart is present' do
      let(:install_command) { described_class.new(prometheus.name, chart: prometheus.chart) }
      let(:command) do
        <<~MSG.chomp
        set -eo pipefail
        apk add -U ca-certificates openssl >/dev/null
        wget -q -O - https://kubernetes-helm.storage.googleapis.com/helm-v2.7.0-linux-amd64.tar.gz | tar zxC /tmp >/dev/null
        mv /tmp/linux-amd64/helm /usr/bin/

        helm init --client-only >/dev/null
        helm install #{prometheus.chart} --name #{prometheus.name} --namespace #{namespace.name} >/dev/null
        MSG
      end

      it 'should return appropriate command' do
        is_expected.to eq(command)
      end
    end
  end

  describe "#pod_name" do
    let(:install_command) { described_class.new(prometheus.name, install_helm: true, chart: prometheus.chart, chart_values_file: true) }
    subject { install_command.send(:pod_name) }

    it { is_expected.to eq('install-prometheus') }
  end
end
