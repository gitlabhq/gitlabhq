# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteSecurityPolicyBotUsers, feature_category: :security_policy_management do
  let(:users) { table(:users) }

  before do
    users.create!(user_type: 10, projects_limit: 0, email: 'security_policy_bot@example.com')
    users.create!(user_type: 1, projects_limit: 0, email: 'support_bot@example.com')
    users.create!(projects_limit: 0, email: 'human@example.com')
  end

  describe '#up' do
    it 'deletes security_policy_bot users' do
      expect { migrate! }.to change { users.count }.by(-1)

      expect(users.where(user_type: 10).count).to eq(0)
      expect(users.where(user_type: 1).count).to eq(1)
      expect(users.where(user_type: nil).count).to eq(1)
    end
  end
end
