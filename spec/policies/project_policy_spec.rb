require 'spec_helper'

describe ProjectPolicy, models: true do
  let(:project) { create(:empty_project, :public) }
  let(:guest) { create(:user) }
  let(:reporter) { create(:user) }
  let(:dev) { create(:user) }
  let(:master) { create(:user) }
  let(:owner) { create(:user) }
  let(:admin) { create(:admin) }

  let(:users_ordered_by_permissions) do
    [nil, guest, reporter, dev, master, owner, admin]
  end

  let(:users_permissions) do
    users_ordered_by_permissions.map { |u| Ability.allowed(u, project).size }
  end

  before do
    project.team << [guest, :guest]
    project.team << [master, :master]
    project.team << [dev, :developer]
    project.team << [reporter, :reporter]

    group = create(:group)
    project.project_group_links.create(
      group: group,
      group_access: Gitlab::Access::MASTER)
    group.add_owner(owner)
  end

  it 'returns increasing permissions for each level' do
    expect(users_permissions).to eq(users_permissions.sort.uniq)
  end
end
