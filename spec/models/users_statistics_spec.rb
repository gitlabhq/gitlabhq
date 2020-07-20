# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersStatistics do
  let(:users_statistics) { build(:users_statistics) }

  describe 'scopes' do
    describe '.order_created_at_desc' do
      it 'returns the entries ordered by created at descending' do
        users_statistics1 = create(:users_statistics, created_at: Time.current)
        users_statistics2 = create(:users_statistics, created_at: Time.current - 2.days)
        users_statistics3 = create(:users_statistics, created_at: Time.current - 5.hours)

        expect(described_class.order_created_at_desc).to eq(
          [
            users_statistics1,
            users_statistics3,
            users_statistics2
          ]
        )
      end
    end
  end

  describe '.latest' do
    it 'returns the latest entry' do
      create(:users_statistics, created_at: Time.current - 1.day)
      users_statistics = create(:users_statistics, created_at: Time.current)

      expect(described_class.latest).to eq(users_statistics)
    end
  end

  describe '.create_current_stats!' do
    before do
      create_list(:user_highest_role, 4)
      create_list(:user_highest_role, 2, :guest)
      create_list(:user_highest_role, 3, :reporter)
      create_list(:user_highest_role, 4, :developer)
      create_list(:user_highest_role, 3, :maintainer)
      create_list(:user_highest_role, 2, :owner)
      create_list(:user, 2, :bot)
      create_list(:user, 1, :blocked)

      allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
    end

    context 'when successful' do
      it 'creates an entry with the current statistics values' do
        expect(described_class.create_current_stats!).to have_attributes(
          without_groups_and_projects: 4,
          with_highest_role_guest: 2,
          with_highest_role_reporter: 3,
          with_highest_role_developer: 4,
          with_highest_role_maintainer: 3,
          with_highest_role_owner: 2,
          bots: 2,
          blocked: 1
        )
      end
    end

    context 'when unsuccessful' do
      it 'raises an ActiveRecord::RecordInvalid exception' do
        allow(UsersStatistics).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

        expect { described_class.create_current_stats! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '#active' do
    it 'sums users statistics values without the value for blocked' do
      expect(users_statistics.active).to eq(71)
    end
  end

  describe '#total' do
    it 'sums all users statistics values' do
      expect(users_statistics.total).to eq(78)
    end
  end
end
