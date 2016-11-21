require 'spec_helper'

describe ProjectGroupLink do
  describe "Associations" do
    it { should belong_to(:group) }
    it { should belong_to(:project) }
  end

  describe "Validation" do
    let!(:project_group_link) { create(:project_group_link) }

    it { should validate_presence_of(:project_id) }
    it { should validate_uniqueness_of(:group_id).scoped_to(:project_id).with_message(/already shared/) }
    it { should validate_presence_of(:group) }
    it { should validate_presence_of(:group_access) }
  end

  describe "destroying a record", truncate: true do
    it "refreshes group users' authorized projects" do
      project     = create(:project, :private)
      group       = create(:group)
      reporter    = create(:user)
      group_users = group.users

      group.add_reporter(reporter)
      project.project_group_links.create(group: group)
      group_users.each { |user| expect(user.authorized_projects).to include(project) }

      project.project_group_links.destroy_all
      group_users.each { |user| expect(user.authorized_projects).not_to include(project) }
    end
  end
end
