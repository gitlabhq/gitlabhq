# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GroupMemberBulkUpdate', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:parent_group) { create(:group) }
  let_it_be(:parent_group_member) { create(:group_member, group: parent_group) }
  let_it_be(:group) { create(:group, parent: parent_group) }
  let_it_be(:source) { group }
  let_it_be(:member_type) { :group_member }
  let_it_be(:mutation_name) { :group_member_bulk_update }
  let_it_be(:source_id_key) { 'group_id' }
  let_it_be(:response_member_field) { 'groupMembers' }

  it_behaves_like 'members bulk update mutation'
end
