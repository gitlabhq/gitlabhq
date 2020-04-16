# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::Fluentd do
  let(:fluentd) { create(:clusters_applications_fluentd) }

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
end
