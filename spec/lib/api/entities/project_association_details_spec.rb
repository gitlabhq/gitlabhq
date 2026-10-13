# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::ProjectAssociationDetails, feature_category: :system_access do
  subject(:entity) { described_class.new(project, options) }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  let(:options) { { current_user: user } }

  describe '#as_json' do
    subject(:as_json) { entity.as_json }

    context 'when current_user has no membership in the project or its group' do
      it 'includes project association fields with nil access levels' do
        is_expected.to eq(
          id: project.id,
          description: project.description,
          name: project.name,
          name_with_namespace: project.name_with_namespace,
          path: project.path,
          path_with_namespace: project.path_with_namespace,
          created_at: project.created_at,
          access_levels: {
            project_access_level: nil,
            group_access_level: nil
          },
          visibility: project.visibility,
          web_url: project.web_url,
          namespace: API::Entities::NamespaceBasic.new(project.namespace, options).as_json
        )
      end
    end

    context 'when current_user is a direct member of the project' do
      before_all do
        project.add_maintainer(user)
      end

      it 'includes the project access level' do
        expect(as_json[:access_levels]).to eq(
          project_access_level: Gitlab::Access::MAINTAINER,
          group_access_level: nil
        )
      end
    end

    context 'when current_user is a member of the project group' do
      before_all do
        group.add_owner(user)
      end

      it 'includes the group access level' do
        expect(as_json[:access_levels]).to eq(
          project_access_level: nil,
          group_access_level: Gitlab::Access::OWNER
        )
      end
    end

    context 'when the project has no group' do
      let_it_be(:personal_project) { create(:project) }

      subject(:entity) { described_class.new(personal_project, options) }

      it 'returns nil for group_access_level' do
        expect(as_json[:access_levels][:group_access_level]).to be_nil
      end
    end
  end
end
