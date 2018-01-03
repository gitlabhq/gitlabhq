require 'spec_helper'

describe Clusters::UpdateService do
  describe '#execute' do
    subject { described_class.new(cluster.project, cluster.user, params).execute(cluster) }

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
  end
end
