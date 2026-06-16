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

    describe '.for_humans' do
      let_it_be(:human_migration) { create(:ghost_user_migration, user: create(:user)) }
      let_it_be(:bot_migration) { create(:ghost_user_migration, user: create(:user, :project_bot)) }
      let_it_be(:service_account_migration) { create(:ghost_user_migration, user: create(:user, :service_account)) }

      it 'returns only migrations for human users' do
        expect(described_class.for_humans).to contain_exactly(human_migration)
      end
    end

    describe '.for_non_humans' do
      let_it_be(:human_migration) { create(:ghost_user_migration, user: create(:user)) }
      let_it_be(:bot_migration) { create(:ghost_user_migration, user: create(:user, :project_bot)) }
      let_it_be(:service_account_migration) { create(:ghost_user_migration, user: create(:user, :service_account)) }

      it 'returns migrations for all non-human users' do
        expect(described_class.for_non_humans).to contain_exactly(bot_migration, service_account_migration)
      end
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
