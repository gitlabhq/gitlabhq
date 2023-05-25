# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ProjectMemberBulkUpdate', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:parent_group) { create(:group) }
  let_it_be(:parent_group_member) { create(:group_member, group: parent_group) }
  let_it_be(:project) { create(:project, group: parent_group) }
  let_it_be(:source) { project }
  let_it_be(:member_type) { :project_member }
  let_it_be(:mutation_name) { :project_member_bulk_update }
  let_it_be(:source_id_key) { 'project_id' }
  let_it_be(:response_member_field) { 'projectMembers' }

  it_behaves_like 'members bulk update mutation'
end
