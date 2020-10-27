# frozen_string_literal: true

RSpec.shared_context 'GroupProjectsFinder context' do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:current_user) { create(:user) }
  let(:params) { {} }
  let(:options) { {} }

  let(:finder) { described_class.new(group: group, current_user: current_user, params: params, options: options) }

  let_it_be(:public_project) { create(:project, :public, group: group, path: '1') }
  let_it_be(:private_project) { create(:project, :private, group: group, path: '2') }
  let_it_be(:shared_project_1) { create(:project, :public, path: '3') }
  let_it_be(:shared_project_2) { create(:project, :private, path: '4') }
  let_it_be(:shared_project_3) { create(:project, :internal, path: '5') }
  let_it_be(:subgroup_project) { create(:project, :public, path: '6', group: subgroup) }
  let_it_be(:subgroup_private_project) { create(:project, :private, path: '7', group: subgroup) }

  before do
    shared_project_1.project_group_links.create!(group_access: Gitlab::Access::MAINTAINER, group: group)
    shared_project_2.project_group_links.create!(group_access: Gitlab::Access::MAINTAINER, group: group)
    shared_project_3.project_group_links.create!(group_access: Gitlab::Access::MAINTAINER, group: group)
  end
end
