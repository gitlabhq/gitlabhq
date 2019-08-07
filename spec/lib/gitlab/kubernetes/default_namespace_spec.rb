# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::DefaultNamespace do
  let(:generator) { described_class.new(cluster, project: environment.project) }

  describe '#from_environment_name' do
    let(:cluster) { create(:cluster) }
    let(:environment) { create(:environment) }

    subject { generator.from_environment_name(environment.name) }

    it 'generates a slug and passes it to #from_environment_slug' do
      expect(Gitlab::Slug::Environment).to receive(:new)
        .with(environment.name)
        .and_return(double(generate: environment.slug))

      expect(generator).to receive(:from_environment_slug)
        .with(environment.slug)
        .and_return(:mock_namespace)

      expect(subject).to eq :mock_namespace
    end
  end

  describe '#from_environment_slug' do
    let(:platform) { create(:cluster_platform_kubernetes, namespace: platform_namespace) }
    let(:cluster) { create(:cluster, platform_kubernetes: platform) }
    let(:project) { create(:project, path: "Path-With-Capitals") }
    let(:environment) { create(:environment, project: project) }

    subject { generator.from_environment_slug(environment.slug) }

    context 'namespace per environment is enabled' do
      context 'platform namespace is specified' do
        let(:platform_namespace) { 'platform-namespace' }

        it { is_expected.to eq "#{platform_namespace}-#{environment.slug}" }

        context 'cluster is unmanaged' do
          let(:cluster) { create(:cluster, :not_managed, platform_kubernetes: platform) }

          it { is_expected.to eq platform_namespace }
        end
      end

      context 'platform namespace is blank' do
        let(:platform_namespace) { nil }
        let(:mock_namespace) { 'mock-namespace' }

        it 'constructs a namespace from the project and environment' do
          expect(Gitlab::NamespaceSanitizer).to receive(:sanitize)
            .with("#{project.path}-#{project.id}-#{environment.slug}".downcase)
            .and_return(mock_namespace)

          expect(subject).to eq mock_namespace
        end
      end
    end

    context 'namespace per environment is disabled' do
      let(:cluster) { create(:cluster, :namespace_per_environment_disabled, platform_kubernetes: platform) }

      context 'platform namespace is specified' do
        let(:platform_namespace) { 'platform-namespace' }

        it { is_expected.to eq platform_namespace }
      end

      context 'platform namespace is blank' do
        let(:platform_namespace) { nil }
        let(:mock_namespace) { 'mock-namespace' }

        it 'constructs a namespace from the project and environment' do
          expect(Gitlab::NamespaceSanitizer).to receive(:sanitize)
            .with("#{project.path}-#{project.id}".downcase)
            .and_return(mock_namespace)

          expect(subject).to eq mock_namespace
        end
      end
    end
  end
end
