# frozen_string_literal: true

require "spec_helper"

RSpec.describe Users::GroupCalloutsHelper, feature_category: :navigation do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:group) { build_stubbed(:group) }

  describe '#show_organizations_available_alert?' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:current_page?).with(group_path(group)).and_return(true)
      allow(helper).to receive(:can_create_organization_from_group_settings?).with(group).and_return(true)
      allow(helper).to receive(:user_dismissed_for_group).with('organizations_available_alert', group).and_return(false)
    end

    describe 'when current user can create organization from group settings' do
      it 'returns true' do
        expect(helper.show_organizations_available_alert?(group)).to be true
      end
    end

    describe 'when current user can not create organization from group settings' do
      before do
        allow(helper).to receive(:can_create_organization_from_group_settings?).with(group).and_return(false)
      end

      it 'returns false' do
        expect(helper.show_organizations_available_alert?(group)).to be false
      end
    end

    describe 'when there is no current user' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it 'returns false' do
        expect(helper.show_organizations_available_alert?(group)).to be false
      end
    end

    describe 'when current page is not the group home page' do
      before do
        allow(helper).to receive(:current_page?).with(group_path(group)).and_return(false)
      end

      it 'returns false' do
        expect(helper.show_organizations_available_alert?(group)).to be false
      end
    end

    describe 'when callout has been dismissed' do
      before do
        allow(helper).to receive(:user_dismissed_for_group)
          .with('organizations_available_alert', group)
          .and_return(true)
      end

      it 'returns false' do
        expect(helper.show_organizations_available_alert?(group)).to be false
      end
    end
  end
end
