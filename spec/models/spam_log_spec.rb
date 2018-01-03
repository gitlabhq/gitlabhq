require 'spec_helper'

describe SpamLog do
  let(:admin) { create(:admin) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }
  end

  describe '#remove_user' do
    it 'blocks the user' do
      spam_log = build(:spam_log)

      expect { spam_log.remove_user(deleted_by: admin) }.to change { spam_log.user.blocked? }.to(true)
    end

    it 'removes the user' do
      spam_log = build(:spam_log)
      user = spam_log.user

      Sidekiq::Testing.inline! do
        spam_log.remove_user(deleted_by: admin)
      end

      expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
