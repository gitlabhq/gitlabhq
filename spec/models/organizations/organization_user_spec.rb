# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUser, type: :model, feature_category: :cell do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).inverse_of(:organization_users).required }
    it { is_expected.to belong_to(:user).inverse_of(:organization_users).required }
  end

  context 'with loose foreign key on organization_users.organization_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:organization) }
      let_it_be(:model) { create(:organization_user, organization: parent) }
    end
  end

  context 'with loose foreign key on organization_users.user_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:user) }
      let_it_be(:model) { create(:organization_user, user: parent) }
    end
  end
end
