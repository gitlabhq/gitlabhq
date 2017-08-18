require 'spec_helper'

describe Gitlab::VisibilityLevel do
  describe '.level_value' do
    it 'converts "public" to integer value' do
      expect(described_class.level_value('public')).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    it 'converts string integer to integer value' do
      expect(described_class.level_value('20')).to eq(20)
    end

    it 'defaults to PRIVATE when string value is not valid' do
      expect(described_class.level_value('invalid')).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'defaults to PRIVATE when integer value is not valid' do
      expect(described_class.level_value(100)).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end
  end

  describe '.levels_for_user' do
    it 'returns all levels for an admin' do
      user = build(:user, :admin)

      expect(described_class.levels_for_user(user))
        .to eq([Gitlab::VisibilityLevel::PRIVATE,
                Gitlab::VisibilityLevel::INTERNAL,
                Gitlab::VisibilityLevel::PUBLIC])
    end

    it 'returns INTERNAL and PUBLIC for internal users' do
      user = build(:user)

      expect(described_class.levels_for_user(user))
        .to eq([Gitlab::VisibilityLevel::INTERNAL,
                Gitlab::VisibilityLevel::PUBLIC])
    end

    it 'returns PUBLIC for external users' do
      user = build(:user, :external)

      expect(described_class.levels_for_user(user))
        .to eq([Gitlab::VisibilityLevel::PUBLIC])
    end

    it 'returns PUBLIC when no user is given' do
      expect(described_class.levels_for_user)
        .to eq([Gitlab::VisibilityLevel::PUBLIC])
    end
  end
end
