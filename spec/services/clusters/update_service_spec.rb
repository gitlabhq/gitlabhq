# frozen_string_literal: true

require 'spec_helper'

describe Clusters::UpdateService do
  include KubernetesHelpers

  describe '#execute' do
    subject { described_class.new(cluster.user, params).execute(cluster) }

    let(:cluster) { create(:cluster, :project, :provided_by_user) }

    context 'when correct params' do
      context 'when enabled is true' do
        let(:params) { { enabled: true } }

        it 'enables cluster' do
          is_expected.to eq(true)
          expect(cluster.enabled).to be_truthy
        end
      end

      context 'when enabled is false' do
        let(:params) { { enabled: false } }

        it 'disables cluster' do
          is_expected.to eq(true)
          expect(cluster.enabled).to be_falsy
        end
      end

      context 'when namespace is specified' do
        let(:params) do
          {
            platform_kubernetes_attributes: {
              namespace: 'custom-namespace'
            }
          }
        end

        before do
          stub_kubeclient_get_namespace('https://kubernetes.example.com', namespace: 'my-namespace')
        end

        it 'updates namespace' do
          is_expected.to eq(true)
          expect(cluster.platform.namespace).to eq('custom-namespace')
        end
      end
    end

    context 'when invalid params' do
      let(:params) do
        {
          platform_kubernetes_attributes: {
            namespace: '!!!'
          }
        }
      end

      it 'returns false' do
        is_expected.to eq(false)
        expect(cluster.errors[:"platform_kubernetes.namespace"]).to be_present
      end
    end

    context 'when cluster is provided by GCP' do
      let(:cluster) { create(:cluster, :project, :provided_by_gcp) }

      let(:params) do
        {
          name: 'my-new-name'
        }
      end

      it 'does not change cluster name' do
        is_expected.to eq(false)

        cluster.reload
        expect(cluster.name).to eq('test-cluster')
      end

      context 'when cluster is being created' do
        let(:cluster) { create(:cluster, :providing_by_gcp) }

        it 'rejects changes' do
          is_expected.to eq(false)

          expect(cluster.errors.full_messages).to include('cannot modify during creation')
        end
      end
    end
  end
end
