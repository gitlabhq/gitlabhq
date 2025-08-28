# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Kubernetes, feature_category: :deployment_management do
  let(:config) { Hash(namespace: 'namespace') }
  let(:agent) { 'path/to/project:example-agent' }

  subject(:kubernetes_config) { described_class.new(config) }

  describe 'attributes' do
    it { is_expected.to respond_to(:namespace) }
    it { is_expected.to respond_to(:has_namespace?) }
  end

  describe 'validations' do
    describe 'config' do
      context 'is a hash containing known keys' do
        let(:config) { Hash(namespace: 'namespace') }

        it { is_expected.to be_valid }
      end

      context 'is a hash containing an unknown key' do
        let(:config) { Hash(unknown: 'attribute') }

        it { is_expected.not_to be_valid }
      end

      context 'is a string' do
        let(:config) { 'config' }

        it { is_expected.not_to be_valid }
      end

      context 'is empty' do
        let(:config) { {} }

        it { is_expected.not_to be_valid }
      end
    end

    describe 'namespace' do
      let(:config) { Hash(namespace: namespace) }

      context 'is a string' do
        let(:namespace) { 'namespace' }

        it { is_expected.to be_valid }
      end

      context 'is a hash' do
        let(:namespace) { Hash(key: 'namespace') }

        it { is_expected.not_to be_valid }
      end

      context 'when both namespace and dashboard[:namespace] are set' do
        let(:namespace) { 'namespace' }
        let(:config) do
          {
            agent: agent,
            namespace: namespace,
            dashboard: { namespace: 'dashboard-namespace' }
          }
        end

        it 'is not valid' do
          expect(kubernetes_config).not_to be_valid
          error_message = 'kubernetes namespace cannot be specified when dashboard.namespace is set'
          expect(kubernetes_config.errors).to include(error_message)
        end
      end
    end

    describe 'agent' do
      let(:config) { Hash(agent: agent) }

      context 'is a string' do
        it { is_expected.to be_valid }
      end

      context 'is a hash' do
        let(:agent) { { key: 'agent' } }

        it { is_expected.not_to be_valid }
      end
    end

    describe 'flux_resource_path' do
      let(:namespace) { 'my-namespace' }
      let(:flux_resource_path) { 'path/to/flux/resource' }

      context 'when both agent and namespace are set' do
        let(:config) { Hash(agent: agent, namespace: namespace, flux_resource_path: flux_resource_path) }

        context 'is a string' do
          it { is_expected.to be_valid }
        end

        context 'is a hash' do
          let(:flux_resource_path) { { key: 'flux_resource_path' } }

          it { is_expected.not_to be_valid }
        end
      end

      context 'when agent is not set' do
        let(:config) { Hash(namespace: namespace, flux_resource_path: flux_resource_path) }

        it { is_expected.not_to be_valid }
      end

      context 'when namespace is not set' do
        let(:config) { Hash(agent: agent, flux_resource_path: flux_resource_path) }

        it { is_expected.not_to be_valid }
      end

      context 'when both flux_resource_path and dashboard[:flux_resource_path] are set' do
        let(:config) do
          {
            agent: agent,
            namespace: namespace,
            flux_resource_path: flux_resource_path,
            dashboard: { flux_resource_path: 'dashboard/flux/resource' }
          }
        end

        it 'is not valid' do
          expect(kubernetes_config).not_to be_valid
          error_message = 'kubernetes flux resource path cannot be specified when dashboard.flux_resource_path is set'
          expect(kubernetes_config.errors).to include(error_message)
        end
      end
    end

    describe 'dashboard' do
      let(:config) { Hash(dashboard: dashboard, agent: 'path/to/project:example-agent') }
      let(:dashboard) { { namespace: 'namespace', flux_resource_path: 'path/to/resource' } }

      context 'when dashboard is a hash' do
        context 'with a hash containing known keys' do
          it { is_expected.to be_valid }
        end

        context 'with only flux_resource_path set' do
          let(:dashboard) { { flux_resource_path: 'path/to/resource' } }

          it { is_expected.not_to be_valid }
        end

        context 'with a hash containing an unknown key' do
          let(:dashboard) { { unknown: 'attribute' } }

          it { is_expected.not_to be_valid }
        end

        context 'with a string' do
          let(:dashboard) { 'config' }

          it { is_expected.not_to be_valid }
        end

        context 'when agent is not set' do
          let(:config) { Hash(dashboard: dashboard) }

          it { is_expected.not_to be_valid }
        end
      end

      context 'when dashboard is not a hash' do
        let(:dashboard) { 'invalid_dashboard' }

        it { is_expected.not_to be_valid }
      end

      context 'when dashboard is nil' do
        let(:dashboard) { nil }

        it { is_expected.to be_valid }
      end

      describe 'namespace' do
        let(:dashboard) { { namespace: namespace } }

        context 'with a string' do
          let(:namespace) { 'namespace' }

          it { is_expected.to be_valid }
        end

        context 'with a blank string' do
          let(:namespace) { '' }

          it { is_expected.not_to be_valid }
        end

        context 'with a hash' do
          let(:namespace) { Hash(key: 'namespace') }

          it { is_expected.not_to be_valid }
        end

        context 'when nil' do
          let(:namespace) { nil }

          it { is_expected.not_to be_valid }
        end
      end

      describe 'flux_resource_path' do
        let(:dashboard) { { flux_resource_path: flux_resource_path, namespace: 'namespace' } }

        context 'with a string' do
          let(:flux_resource_path) { 'path/to/resource' }

          context 'when namespace is present' do
            it { is_expected.to be_valid }
          end

          context 'when namespace is not present' do
            let(:dashboard) { { flux_resource_path: flux_resource_path } }

            it { is_expected.not_to be_valid }
          end
        end

        context 'with a hash' do
          let(:flux_resource_path) { Hash(key: 'path/to/resource') }

          it { is_expected.not_to be_valid }
        end
      end
    end

    describe 'managed_resources' do
      let(:config) { Hash(agent: agent, managed_resources: managed_resources) }

      context 'when managed_resources is a hash' do
        describe 'enabled' do
          context 'with a TrueClass' do
            let(:managed_resources) { { enabled: true } }

            it { is_expected.to be_valid }
          end

          context 'with a FalseClass' do
            let(:managed_resources) { { enabled: false } }

            it { is_expected.to be_valid }
          end

          context 'with a string' do
            let(:managed_resources) { { enabled: 'true' } }

            it { is_expected.not_to be_valid }
          end

          context 'with a hash' do
            let(:managed_resources) { { enabled: { key: 'value' } } }

            it { is_expected.not_to be_valid }
          end

          context 'with nil' do
            let(:managed_resources) { { enabled: nil } }

            it { is_expected.not_to be_valid }
          end
        end
      end

      context 'when managed_resources is a hash with an unknown key' do
        let(:managed_resources) { { unknown: 'attribute' } }

        it { is_expected.not_to be_valid }
      end

      context 'when managed_resources is not a hash' do
        let(:managed_resources) { 'enabled' }

        it { is_expected.not_to be_valid }
      end

      context 'when managed_resources is nil' do
        let(:managed_resources) { nil }

        it { is_expected.to be_valid }
      end
    end
  end
end
