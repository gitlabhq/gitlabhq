# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Management::ValidateManagementProjectPermissionsService, feature_category: :deployment_management do
  describe '#execute' do
    subject { described_class.new(user).execute(cluster, management_project_id) }

    let(:cluster) { build(:cluster, :project, projects: [create(:project)]) }
    let(:user) { create(:user) }

    context 'when management_project_id is nil' do
      let(:management_project_id) { nil }

      it { is_expected.to be true }
    end

    context 'when management_project_id is not nil' do
      let(:management_project_id) { management_project.id }
      let(:management_project_namespace) { create(:group) }
      let(:management_project) { create(:project, namespace: management_project_namespace) }

      context 'when management_project does not exist' do
        let(:management_project_id) { 0 }

        it 'adds errors to the cluster and returns false' do
          is_expected.to eq false

          expect(cluster.errors[:management_project_id]).to include('Project does not exist or you don\'t have permission to perform this action')
        end
      end

      shared_examples 'management project is in scope' do
        context 'when user is authorized to administer manangement_project' do
          before do
            management_project.add_maintainer(user)
          end

          it 'adds no error and returns true' do
            is_expected.to eq true

            expect(cluster.errors).to be_empty
          end
        end

        context 'when user is not authorized to adminster manangement_project' do
          it 'adds an error and returns false' do
            is_expected.to eq false

            expect(cluster.errors[:management_project_id]).to include('Project does not exist or you don\'t have permission to perform this action')
          end
        end
      end

      shared_examples 'management project is out of scope' do
        context 'when manangement_project is outside of the namespace scope' do
          let(:management_project_namespace) { create(:group) }

          it 'adds an error and returns false' do
            is_expected.to eq false

            expect(cluster.errors[:management_project_id]).to include('Project does not exist or you don\'t have permission to perform this action')
          end
        end
      end

      context 'project cluster' do
        let(:cluster) { build(:cluster, :project, projects: [create(:project, namespace: management_project_namespace)]) }

        include_examples 'management project is in scope'
        include_examples 'management project is out of scope'
      end

      context 'group cluster' do
        let(:cluster) { build(:cluster, :group, groups: [management_project_namespace]) }

        include_examples 'management project is in scope'
        include_examples 'management project is out of scope'
      end

      context 'instance cluster' do
        let(:cluster) { build(:cluster, :instance) }

        include_examples 'management project is in scope'
      end
    end
  end
end
