# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUserPolicy, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:current_user) { create :user }

  subject(:policy) { described_class.new(current_user, organization_user) }

  context 'when the user is not an owner' do
    let(:organization_user) { build(:organization_user, organization: organization, user: current_user) }

    it { is_expected.to be_allowed(:remove_user) }
  end

  context 'when the user is last owner' do
    let(:organization_user) { build(:organization_user, :owner, organization: organization, user: current_user) }

    it { is_expected.to be_disallowed(:remove_user) }
  end

  context 'when the user is not last owner' do
    let(:organization_user) { build(:organization_user, :owner, organization: organization, user: current_user) }

    before do
      create(:organization_user, :owner, organization: organization)
    end

    it { is_expected.to be_allowed(:remove_user) }
  end
end
