# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteUserCalloutAlertsMoved do
  let(:users) { table(:users) }
  let(:user_callouts) { table(:user_callouts) }
  let(:alerts_moved_feature) { described_class::FEATURE_NAME_ALERTS_MOVED }
  let(:unrelated_feature) { 1 }

  let!(:user1) { users.create!(email: '1', projects_limit: 0) }
  let!(:user2) { users.create!(email: '2', projects_limit: 0) }

  subject(:migration) { described_class.new }

  before do
    user_callouts.create!(user_id: user1.id, feature_name: alerts_moved_feature)
    user_callouts.create!(user_id: user1.id, feature_name: unrelated_feature)
    user_callouts.create!(user_id: user2.id, feature_name: alerts_moved_feature)
  end

  describe '#up' do
    it 'deletes `alerts_moved` user callouts' do
      migration.up

      expect(user_callouts.all.map(&:feature_name)).to eq([unrelated_feature])
    end
  end
end
