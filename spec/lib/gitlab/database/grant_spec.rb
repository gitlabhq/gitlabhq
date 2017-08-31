require 'spec_helper'

describe Gitlab::Database::Grant do
  describe '.scope_to_current_user' do
    it 'scopes the relation to the current user' do
      user = Gitlab::Database.username
      column = Gitlab::Database.postgresql? ? :grantee : :User
      names = described_class.scope_to_current_user.pluck(column).uniq

      expect(names).to eq([user])
    end
  end

  describe '.create_and_execute_trigger' do
    it 'returns true when the user can create and execute a trigger' do
      # We assume the DB/user is set up correctly so that triggers can be
      # created, which is necessary anyway for other tests to work.
      expect(described_class.create_and_execute_trigger?('users')).to eq(true)
    end

    it 'returns false when the user can not create and/or execute a trigger' do
      allow(described_class).to receive(:scope_to_current_user)
        .and_return(described_class.none)

      result = described_class.create_and_execute_trigger?('kittens')

      expect(result).to eq(false)
    end
  end
end
