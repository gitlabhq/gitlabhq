require 'rails_helper'

describe UserAgentDetail do
  describe '.submittable?' do
    it 'is submittable when not already submitted' do
      detail = build(:user_agent_detail)

      expect(detail.submittable?).to be_truthy
    end

    it 'is not submittable when already submitted' do
      detail = build(:user_agent_detail, submitted: true)

      expect(detail.submittable?).to be_falsey
    end
  end

  describe '.valid?' do
    it 'is valid with a subject' do
      detail = build(:user_agent_detail)

      expect(detail).to be_valid
    end

    it 'is invalid without a subject' do
      detail = build(:user_agent_detail, subject: nil)

      expect(detail).not_to be_valid
    end
  end
end
