# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::Groups::CreatorService do
  it_behaves_like 'member creation' do
    let_it_be(:source, reload: true) { create(:group, :public) }
    let_it_be(:member_type) { GroupMember }
  end

  describe '.access_levels' do
    it 'returns Gitlab::Access.options_with_owner' do
      expect(described_class.access_levels).to eq(Gitlab::Access.sym_options_with_owner)
    end
  end
end
