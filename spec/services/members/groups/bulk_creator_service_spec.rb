# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::Groups::BulkCreatorService do
  it_behaves_like 'bulk member creation' do
    let_it_be(:source, reload: true) { create(:group, :public) }
    let_it_be(:member_type) { GroupMember }
  end
end
