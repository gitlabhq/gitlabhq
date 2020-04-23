# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::Fluentd do
  let(:waf_log_enabled) { true }
  let(:cilium_log_enabled) { true }
  let(:fluentd) { create(:clusters_applications_fluentd, waf_log_enabled: waf_log_enabled, cilium_log_enabled: cilium_log_enabled) }

  include_examples 'cluster application core specs', :clusters_applications_fluentd
  include_examples 'cluster application status specs', :clusters_applications_fluentd
  include_examples 'cluster application version specs', :clusters_applications_fluentd
  include_examples 'cluster application initial status specs'

  describe '#can_uninstall?' do
    subject { fluentd.can_uninstall? }

    it { is_expected.to be true }
  end

  describe '#install_command' do
    subject { fluentd.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'is initialized with fluentd arguments' do
      expect(subject.name).to eq('fluentd')
      expect(subject.chart).to eq('stable/fluentd')
      expect(subject.version).to eq('2.4.0')
      expect(subject).to be_rbac
    end

    context 'application failed to install previously' do
      let(:fluentd) { create(:clusters_applications_fluentd, :errored, version: '0.0.1') }

      it 'is initialized with the locked version' do
        expect(subject.version).to eq('2.4.0')
      end
    end
  end

  describe '#files' do
    let(:application) { fluentd }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'includes fluentd specific keys in the values.yaml file' do
      expect(values).to include('output.conf', 'general.conf')
    end
  end

  describe '#values' do
    let(:modsecurity_log_path) { "/var/log/containers/*#{Clusters::Applications::Ingress::MODSECURITY_LOG_CONTAINER_NAME}*.log" }
    let(:cilium_log_path) { "/var/log/containers/*#{described_class::CILIUM_CONTAINER_NAME}*.log" }

    subject { fluentd.values }

    context 'with both logs variables set to false' do
      let(:waf_log_enabled) { false }
      let(:cilium_log_enabled) { false }

      it "raises ActiveRecord::RecordInvalid" do
        expect {subject}.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with both logs variables set to true' do
      it { is_expected.to include("#{modsecurity_log_path},#{cilium_log_path}") }
    end

    context 'with waf_log_enabled set to true' do
      let(:cilium_log_enabled) { false }

      it { is_expected.to include(modsecurity_log_path) }
    end

    context 'with cilium_log_enabled set to true' do
      let(:waf_log_enabled) { false }

      it { is_expected.to include(cilium_log_path) }
    end
  end
end
