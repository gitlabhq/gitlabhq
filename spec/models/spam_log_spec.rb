require 'spec_helper'

describe SpamLog, models: true do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }
  end

  describe '#remove_user' do
    it 'blocks the user' do
      spam_log = build(:spam_log)

      expect { spam_log.remove_user }.to change { spam_log.user.blocked? }.to(true)
    end

    it 'removes the user' do
      spam_log = build(:spam_log)

      expect { spam_log.remove_user }.to change { User.count }.by(-1)
    end
  end
end
