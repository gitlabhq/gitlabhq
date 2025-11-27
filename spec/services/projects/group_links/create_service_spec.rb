# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupLinks::CreateService, '#execute', feature_category: :groups_and_projects do
  let_it_be(:user) { create :user }
  let_it_be(:group) { create :group }
  let_it_be(:project) { create(:project, namespace: create(:namespace, :with_namespace_settings)) }
  let_it_be(:group_user) { create(:user, maintainer_of: group) }

  let(:opts) do
    {
      link_group_access: Gitlab::Access::DEVELOPER,
      expires_at: nil
    }
  end

  subject { described_class.new(project, group, user, opts) }

  shared_examples_for 'not shareable' do
    it 'does not share and returns an error' do
      expect do
        result = subject.execute

        expect(result[:status]).to eq(:error)
        expect(result[:http_status]).to eq(404)
      end.not_to change { project.project_group_links.count }
    end
  end

  shared_examples_for 'shareable' do
    it 'adds group to project' do
      expect do
        result = subject.execute

        expect(result[:status]).to eq(:success)
      end.to change { project.project_group_links.count }.from(0).to(1)
    end
  end

  context 'when user has proper permissions to share a project with a group' do
    before do
      group.add_guest(user)
    end

    context 'when the user is an OWNER in the project' do
      before do
        project.add_owner(user)
      end

      it_behaves_like 'shareable'

      context 'when sharing it to a group with OWNER access' do
        let(:opts) do
          {
            link_group_access: Gitlab::Access::OWNER,
            expires_at: nil
          }
        end

        it_behaves_like 'shareable'
      end
    end
  end

  context 'when user does not have permissions to share the project with a group' do
    it_behaves_like 'not shareable'

    context 'when the user has less than OWNER access in the project' do
      before do
        group.add_guest(user)
        project.add_maintainer(user)
      end

      it_behaves_like 'not shareable'
    end
  end

  context 'when group is blank' do
    let(:group) { nil }

    it_behaves_like 'not shareable'
  end
end
