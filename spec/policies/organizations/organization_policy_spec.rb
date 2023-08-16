# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationPolicy, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }

  subject(:policy) { described_class.new(current_user, organization) }

  context 'when the user is anonymous' do
    let_it_be(:current_user) { nil }

    it { is_expected.to be_allowed(:read_organization) }
  end

  context 'when the user is an admin' do
    let_it_be(:current_user) { create(:user, :admin) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed(:admin_organization) }
      it { is_expected.to be_allowed(:read_organization) }
    end

    context 'when admin mode is disabled' do
      it { is_expected.to be_disallowed(:admin_organization) }
      it { is_expected.to be_allowed(:read_organization) }
    end
  end

  context 'when the user is an organization user' do
    let_it_be(:current_user) { create :user }

    before do
      create :organization_user, organization: organization, user: current_user
    end

    it { is_expected.to be_allowed(:read_organization) }
  end
end
