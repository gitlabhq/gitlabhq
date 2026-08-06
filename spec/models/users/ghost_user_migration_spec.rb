# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::GhostUserMigration do
  describe 'enums' do
    it { is_expected.to define_enum_for(:user_type).with_values(HasUserType::USER_TYPES) }
  end

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

  describe 'before_create' do
    context 'for set_user_type' do
      let(:ghost_user_migration) { build(:ghost_user_migration, user: create(:user)) }

      it 'sets user_type' do
        ghost_user_migration.user_type = nil

        ghost_user_migration.save!

        expect(ghost_user_migration.user_type).to eq(ghost_user_migration.user.user_type)
      end
    end
  end
end
