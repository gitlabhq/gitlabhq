module GroupAccessHelper
  def group(visibility_level=0)
    @group ||= create(:group, visibility_level: visibility_level)
  end

  def project_group_member(access_level)
    project = create(:project, visibility_level: group.visibility_level, group: group, name: 'B', path: 'B')

    create(:user).tap { |user| project.team.add_user(user, Gitlab::Access::DEVELOPER) }
  end

  def group_member(access_level, grp=group())
    level = Object.const_get("Gitlab::Access::#{access_level.upcase}")

    create(:user).tap { |user| grp.add_user(user, level) }
  end
end
