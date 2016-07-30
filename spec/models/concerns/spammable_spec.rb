require 'spec_helper'

describe Issue, 'Spammable' do
  let(:issue) { create(:issue, description: 'Test Desc.') }

  describe 'Associations' do
    it { is_expected.to have_one(:user_agent_detail).dependent(:destroy) }
  end

  describe 'ClassMethods' do
    it 'should return correct attr_spammable' do
      expect(issue.send(:spammable_text)).to eq("#{issue.title}\n#{issue.description}")
    end
  end

  describe 'InstanceMethods' do
    it 'should return the correct creator' do
      expect(issue.send(:owner).id).to eq(issue.author_id)
    end

    it 'should be invalid if spam' do
      issue.spam = true
      expect(issue.valid?).to be_truthy
    end

    it 'should be submittable' do
      create(:user_agent_detail, subject_id: issue.id, subject_type: issue.class.to_s)
      expect(issue.can_be_submitted?).to be_truthy
    end

    describe '#check_for_spam?' do
      before do
        allow_any_instance_of(Gitlab::AkismetHelper).to receive(:akismet_enabled?).and_return(true)
      end
      it 'returns true for public project' do
        issue.project.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
        expect(issue.check_for_spam?).to eq(true)
      end

      it 'returns false for other visibility levels' do
        expect(issue.check_for_spam?).to eq(false)
      end
    end
  end

  describe 'AkismetMethods' do
    before do
      allow_any_instance_of(Gitlab::AkismetHelper).to receive_messages(is_spam?: true, spam!: nil)
    end

    it { expect(issue.spam_detected?(:mock_env)).to be_truthy }
    it { expect(issue.submit_spam).to be_nil }
  end
end
