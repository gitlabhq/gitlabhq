# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::CreatorService, feature_category: :groups_and_projects do
  let_it_be(:source, reload: true) { create(:group, :public) }
  let_it_be(:member_type) { GroupMember }
  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { create(:user) }

  describe '#execute' do
    it 'raises error for new member on authorization check implementation' do
      expect do
        described_class.add_member(source, user, :maintainer, current_user: current_user)
      end.to raise_error(NotImplementedError)
    end

    it 'raises error for an existing member on authorization check implementation' do
      source.add_developer(user)

      expect do
        described_class.add_member(source, user, :maintainer, current_user: current_user)
      end.to raise_error(NotImplementedError)
    end
  end
end
