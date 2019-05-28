# frozen_string_literal: true

require 'spec_helper'

describe Spammable do
  let(:issue) { create(:issue, description: 'Test Desc.') }

  describe 'Associations' do
    subject { build(:issue) }

    it { is_expected.to have_one(:user_agent_detail).dependent(:destroy) }
  end

  describe 'ClassMethods' do
    it 'returns correct attr_spammable' do
      expect(issue.spammable_text).to eq("#{issue.title}\n#{issue.description}")
    end
  end

  describe 'InstanceMethods' do
    let(:issue) { build(:issue, spam: true) }

    it 'is invalid if spam' do
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

    describe '#submittable_as_spam_by?' do
      let(:admin) { build(:admin) }
      let(:user) { build(:user) }

      before do
        allow(issue).to receive(:submittable_as_spam?).and_return(true)
      end

      it 'tests if the user can submit spam' do
        expect(issue.submittable_as_spam_by?(admin)).to be(true)
        expect(issue.submittable_as_spam_by?(user)).to be(false)
        expect(issue.submittable_as_spam_by?(nil)).to be_nil
      end
    end
  end
end
