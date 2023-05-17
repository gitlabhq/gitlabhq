# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::BuildKubernetesNamespaceService, feature_category: :deployment_management do
  let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
  let(:environment) { create(:environment) }
  let(:project) { environment.project }

  let(:namespace_generator) { double(from_environment_slug: namespace) }
  let(:namespace) { 'namespace' }

  subject { described_class.new(cluster, environment: environment).execute }

  before do
    allow(Gitlab::Kubernetes::DefaultNamespace).to receive(:new).and_return(namespace_generator)
  end

  shared_examples 'shared attributes' do
    it 'initializes a new namespace and sets default values' do
      expect(subject).to be_new_record
      expect(subject.cluster).to eq cluster
      expect(subject.project).to eq project
      expect(subject.namespace).to eq namespace
      expect(subject.service_account_name).to eq "#{namespace}-service-account"
    end
  end

  include_examples 'shared attributes'

  it 'sets cluster_project and environment' do
    expect(subject.cluster_project).to eq cluster.cluster_project
    expect(subject.environment).to eq environment
  end

  context 'namespace per environment is disabled' do
    let(:cluster) { create(:cluster, :project, :provided_by_gcp, :namespace_per_environment_disabled) }

    include_examples 'shared attributes'

    it 'does not set environment' do
      expect(subject.cluster_project).to eq cluster.cluster_project
      expect(subject.environment).to be_nil
    end
  end

  context 'group cluster' do
    let(:cluster) { create(:cluster, :group, :provided_by_gcp) }

    include_examples 'shared attributes'

    it 'does not set cluster_project' do
      expect(subject.cluster_project).to be_nil
      expect(subject.environment).to eq environment
    end
  end
end
