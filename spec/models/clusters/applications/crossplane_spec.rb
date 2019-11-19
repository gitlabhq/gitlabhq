# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::Crossplane do
  let(:crossplane) { create(:clusters_applications_crossplane) }

  include_examples 'cluster application core specs', :clusters_applications_crossplane
  include_examples 'cluster application status specs', :clusters_applications_crossplane
  include_examples 'cluster application version specs', :clusters_applications_crossplane
  include_examples 'cluster application initial status specs'

  describe 'validations' do
    it { is_expected.to validate_presence_of(:stack) }
  end

  describe '#can_uninstall?' do
    subject { crossplane.can_uninstall? }

    it { is_expected.to be_truthy }
  end

  describe '#install_command' do
    let(:stack) { 'gcp' }

    subject { crossplane.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'is initialized with crossplane arguments' do
      expect(subject.name).to eq('crossplane')
      expect(subject.chart).to eq('crossplane/crossplane')
      expect(subject.repository).to eq('https://charts.crossplane.io/alpha')
      expect(subject.version).to eq('0.4.1')
      expect(subject).to be_rbac
    end

    context 'application failed to install previously' do
      let(:crossplane) { create(:clusters_applications_crossplane, :errored, version: '0.0.1') }

      it 'is initialized with the locked version' do
        expect(subject.version).to eq('0.4.1')
      end
    end
  end

  describe '#files' do
    let(:application) { crossplane }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'includes crossplane specific keys in the values.yaml file' do
      expect(values).to include('clusterStacks')
    end
  end
end
