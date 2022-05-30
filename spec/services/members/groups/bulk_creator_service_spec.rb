# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::Groups::BulkCreatorService do
  let_it_be(:source, reload: true) { create(:group, :public) }
  let_it_be(:current_user) { create(:user) }

  it_behaves_like 'bulk member creation' do
    let_it_be(:member_type) { GroupMember }
  end

  it_behaves_like 'owner management'
end
