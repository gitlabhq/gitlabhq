# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::UpdateService, feature_category: :deployment_management do
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

      context 'when service token is empty' do
        let(:params) do
          {
              platform_kubernetes_attributes: {
                  token: ''
              }
          }
        end

        it 'does not update the token' do
          current_token = cluster.platform.token
          is_expected.to eq(true)
          cluster.platform.reload

          expect(cluster.platform.token).to eq(current_token)
        end
      end

      context 'when service token is not empty' do
        let(:params) do
          {
              platform_kubernetes_attributes: {
                  token: 'new secret token'
              }
          }
        end

        it 'updates the token' do
          is_expected.to eq(true)
          expect(cluster.platform.token).to eq('new secret token')
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

          expect(cluster.errors.full_messages).to include('Cannot modify provider during creation')
        end
      end
    end

    context 'when params includes :management_project_id' do
      context 'management_project is non-existent' do
        let(:params) do
          { management_project_id: 0 }
        end

        it 'does not update management_project_id' do
          is_expected.to eq(false)

          expect(cluster.errors[:management_project_id]).to include('Project does not exist or you don\'t have permission to perform this action')

          cluster.reload
          expect(cluster.management_project_id).to be_nil
        end
      end

      shared_examples 'setting a management project' do
        context 'user is authorized to adminster manangement_project' do
          before do
            management_project.add_maintainer(cluster.user)
          end

          let(:params) do
            { management_project_id: management_project.id }
          end

          it 'updates management_project_id' do
            is_expected.to eq(true)

            expect(cluster.management_project).to eq(management_project)
          end
        end

        context 'user is not authorized to adminster manangement_project' do
          let(:params) do
            { management_project_id: management_project.id }
          end

          it 'does not update management_project_id' do
            is_expected.to eq(false)

            expect(cluster.errors[:management_project_id]).to include('Project does not exist or you don\'t have permission to perform this action')

            cluster.reload
            expect(cluster.management_project_id).to be_nil
          end
        end

        context 'cluster already has a management project set' do
          before do
            cluster.update!(management_project: create(:project))
          end

          let(:params) do
            { management_project_id: '' }
          end

          it 'unsets management_project_id' do
            is_expected.to eq(true)

            cluster.reload
            expect(cluster.management_project_id).to be_nil
          end
        end
      end

      context 'project cluster' do
        include_examples 'setting a management project' do
          let(:management_project) { create(:project, namespace: cluster.first_project.namespace) }
        end

        context 'manangement_project is outside of the namespace scope' do
          before do
            management_project.update!(group: create(:group))
          end

          let(:params) do
            { management_project_id: management_project.id }
          end

          it 'does not update management_project_id' do
            is_expected.to eq(false)

            expect(cluster.errors[:management_project_id]).to include('Project does not exist or you don\'t have permission to perform this action')

            cluster.reload
            expect(cluster.management_project_id).to be_nil
          end
        end
      end

      context 'group cluster' do
        let(:cluster) { create(:cluster, :group) }

        include_examples 'setting a management project' do
          let(:management_project) { create(:project, group: cluster.first_group) }
        end

        context 'manangement_project is outside of the namespace scope' do
          before do
            management_project.update!(group: create(:group))
          end

          let(:params) do
            { management_project_id: management_project.id }
          end

          it 'does not update management_project_id' do
            is_expected.to eq(false)

            expect(cluster.errors[:management_project_id]).to include('Project does not exist or you don\'t have permission to perform this action')

            cluster.reload
            expect(cluster.management_project_id).to be_nil
          end
        end
      end

      context 'instance cluster' do
        let(:cluster) { create(:cluster, :instance) }

        include_examples 'setting a management project' do
          let(:management_project) { create(:project) }
        end
      end
    end
  end
end
