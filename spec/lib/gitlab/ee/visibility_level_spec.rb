require 'spec_helper'

describe Gitlab::VisibilityLevel do  # rubocop:disable RSpec/FilePath
  describe '.levels_for_user' do
    it 'returns all levels for an auditor' do
      user = build(:user, :auditor)

      expect(described_class.levels_for_user(user))
        .to eq([Gitlab::VisibilityLevel::PRIVATE,
                Gitlab::VisibilityLevel::INTERNAL,
                Gitlab::VisibilityLevel::PUBLIC])
    end
  end
end
