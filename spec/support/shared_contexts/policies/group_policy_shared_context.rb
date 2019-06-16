# frozen_string_literal: true

RSpec.shared_context 'GroupPolicy context' do
  let(:guest) { create(:user) }
  let(:reporter) { create(:user) }
  let(:developer) { create(:user) }
  let(:maintainer) { create(:user) }
  let(:owner) { create(:user) }
  let(:admin) { create(:admin) }
  let(:group) { create(:group, :private, :owner_subgroup_creation_only) }

  let(:guest_permissions) do
    %i[
      read_label read_group upload_file read_namespace read_group_activity
      read_group_issues read_group_boards read_group_labels read_group_milestones
      read_group_merge_requests
   ]
  end
  let(:reporter_permissions) { [:admin_label] }
  let(:developer_permissions) { [:admin_milestone] }
  let(:maintainer_permissions) do
    [
      :create_projects,
      :read_cluster,
      :create_cluster,
      :update_cluster,
      :admin_cluster,
      :add_cluster,
      (Gitlab::Database.postgresql? ? :create_subgroup : nil)
    ].compact
  end
  let(:owner_permissions) do
    [
      :admin_group,
      :admin_namespace,
      :admin_group_member,
      :change_visibility_level,
      :set_note_created_at
    ].compact
  end

  before do
    group.add_guest(guest)
    group.add_reporter(reporter)
    group.add_developer(developer)
    group.add_maintainer(maintainer)
    group.add_owner(owner)
  end

  subject { described_class.new(current_user, group) }
end
