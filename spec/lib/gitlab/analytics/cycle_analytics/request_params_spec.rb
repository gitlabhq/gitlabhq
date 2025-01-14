# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::RequestParams, feature_category: :value_stream_management do
  it_behaves_like 'unlicensed cycle analytics request params' do
    let_it_be(:user) { create(:user) }
    let_it_be(:root_group) { create(:group) }
    let_it_be_with_refind(:project) { create(:project, group: root_group) }

    let(:namespace) { project.project_namespace }

    describe 'project-level data attributes' do
      subject(:attributes) { described_class.new(params).to_data_attributes }

      it 'includes the namespace attribute' do
        expect(attributes).to match(hash_including({
          namespace: {
            name: project.name,
            type: "Project",
            path: project.full_path,
            rest_api_request_path: project.full_path
          }
        }))
      end

      context 'with a subgroup project' do
        let_it_be(:sub_group) { create(:group, parent: root_group) }
        let_it_be_with_refind(:subgroup_project) { create(:project, group: sub_group) }
        let(:namespace) { subgroup_project.project_namespace }

        it 'includes the correct group_path' do
          expect(attributes).to match(hash_including({
            group_path: "groups/#{subgroup_project.namespace.full_path}",
            full_path: subgroup_project.full_path
          }))
        end
      end
    end
  end
end
