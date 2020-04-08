# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersStatistics do
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
end
