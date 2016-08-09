require 'spec_helper'

describe Issue, 'Spammable' do
  let(:issue) { create(:issue, description: 'Test Desc.') }

  describe 'Associations' do
    it { is_expected.to have_one(:user_agent_detail).dependent(:destroy) }
  end

  describe 'ClassMethods' do
    it 'should return correct attr_spammable' do
      expect(issue.spammable_text).to eq("#{issue.title}\n#{issue.description}")
    end
  end

  describe 'InstanceMethods' do
    it 'should be invalid if spam' do
      issue = build(:issue, spam: true)
      expect(issue.valid?).to be_falsey
    end

    describe '#check_for_spam?' do
      it 'returns true for public project' do
        issue.project.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
        expect(issue.check_for_spam?).to eq(true)
      end

      it 'returns false for other visibility levels' do
        expect(issue.check_for_spam?).to eq(false)
      end
    end
  end
end
