# frozen_string_literal: true

RSpec.shared_context 'GroupProjectsFinder context' do
  let_it_be(:root_group) { create(:group) }
  let_it_be(:group) { create(:group, parent: root_group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:current_user) { create(:user) }
  let(:params) { {} }
  let(:options) { {} }

  let(:finder) { described_class.new(group: group, current_user: current_user, params: params, options: options) }

  let_it_be(:public_project) { create(:project, :public, group: group, path: '1', name: 'g') }
  let_it_be(:private_project) { create(:project, :private, group: group, path: '2', name: 'f') }
  let_it_be(:shared_project_1) { create(:project, :public, path: '3', name: 'e') }
  let_it_be(:shared_project_2) { create(:project, :private, path: '4', name: 'd') }
  let_it_be(:shared_project_3) { create(:project, :internal, path: '5', name: 'c') }
  let_it_be(:subgroup_project) { create(:project, :public, path: '6', group: subgroup, name: 'b') }
  let_it_be(:subgroup_private_project) { create(:project, :private, path: '7', group: subgroup, name: 'a') }
  let_it_be(:root_group_public_project) { create(:project, :public, path: '8', group: root_group, name: 'root-public-project') }
  let_it_be(:root_group_private_project) { create(:project, :private, path: '9', group: root_group, name: 'root-private-project') }
  let_it_be(:root_group_private_project_2) { create(:project, :private, path: '10', group: root_group, name: 'root-private-project-2') }

  before do
    shared_project_1.project_group_links.create!(group_access: Gitlab::Access::MAINTAINER, group: group)
    shared_project_2.project_group_links.create!(group_access: Gitlab::Access::MAINTAINER, group: group)
    shared_project_3.project_group_links.create!(group_access: Gitlab::Access::MAINTAINER, group: group)
  end
end
