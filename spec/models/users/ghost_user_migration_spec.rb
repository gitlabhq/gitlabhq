# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::GhostUserMigration do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:initiator_user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user_id) }
  end

  describe 'scopes' do
    describe '.consume_order' do
      let!(:ghost_user_migration_1) { create(:ghost_user_migration, consume_after: Time.current) }
      let!(:ghost_user_migration_2) { create(:ghost_user_migration, consume_after: 5.minutes.ago) }

      subject { described_class.consume_order.to_a }

      it { is_expected.to eq([ghost_user_migration_2, ghost_user_migration_1]) }
    end
  end
end
