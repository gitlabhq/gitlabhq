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

  it 'does not include the read_issue permission when the issue author is not a member of the private project' do
    project = create(:project, :private)
    issue   = create(:issue, project: project)
    user    = issue.author

    expect(project.team.member?(issue.author)).to eq(false)

    expect(BasePolicy.class_for(project).abilities(user, project).can_set).
      not_to include(:read_issue)

    expect(Ability.allowed?(user, :read_issue, project)).to be_falsy
  end
end
