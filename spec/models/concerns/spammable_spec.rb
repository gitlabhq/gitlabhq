# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spammable do
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

        expect(issue.check_for_spam?(user: issue.author)).to eq(true)
      end

      it 'returns false for other visibility levels' do
        expect(issue.check_for_spam?(user: issue.author)).to eq(false)
      end
    end

    describe '#invalidate_if_spam' do
      using RSpec::Parameterized::TableSyntax

      before do
        stub_application_setting(recaptcha_enabled: true)
      end

      context 'when the model is spam' do
        subject { invalidate_if_spam(is_spam: true) }

        it 'has an error related to spam on the model' do
          expect(subject.errors.messages[:base]).to match_array /has been discarded/
        end
      end

      context 'when the model needs recaptcha' do
        subject { invalidate_if_spam(needs_recaptcha: true) }

        it 'has an error related to spam on the model' do
          expect(subject.errors.messages[:base]).to match_array /solve the reCAPTCHA/
        end
      end

      context 'if the model is spam and also needs recaptcha' do
        subject { invalidate_if_spam(is_spam: true, needs_recaptcha: true) }

        it 'has an error related to spam on the model' do
          expect(subject.errors.messages[:base]).to match_array /solve the reCAPTCHA/
        end
      end

      context 'when the model is not spam nor needs recaptcha' do
        subject { invalidate_if_spam }

        it 'returns no error' do
          expect(subject.errors.messages[:base]).to be_empty
        end
      end

      context 'if recaptcha is not enabled and the model needs recaptcha' do
        before do
          stub_application_setting(recaptcha_enabled: false)
        end

        subject { invalidate_if_spam(needs_recaptcha: true) }

        it 'has no errors' do
          expect(subject.errors.messages[:base]).to match_array /has been discarded/
        end
      end

      def invalidate_if_spam(is_spam: false, needs_recaptcha: false)
        issue.tap do |i|
          i.spam = is_spam
          i.needs_recaptcha = needs_recaptcha
          i.invalidate_if_spam
        end
      end
    end

    describe 'spam flags' do
      before do
        issue.spam = false
        issue.needs_recaptcha = false
      end

      describe '#spam!' do
        it 'adds only `spam` flag' do
          issue.spam!

          expect(issue.spam).to be_truthy
          expect(issue.needs_recaptcha).to be_falsey
        end
      end

      describe '#needs_recaptcha!' do
        it 'adds `needs_recaptcha` flag' do
          issue.needs_recaptcha!

          expect(issue.spam).to be_falsey
          expect(issue.needs_recaptcha).to be_truthy
        end
      end

      describe '#render_recaptcha?' do
        before do
          allow(Gitlab::Recaptcha).to receive(:enabled?) { recaptcha_enabled }
        end

        context 'when recaptcha is not enabled' do
          let(:recaptcha_enabled) { false }

          it 'returns false' do
            expect(issue.render_recaptcha?).to eq(false)
          end
        end

        context 'when recaptcha is enabled' do
          let(:recaptcha_enabled) { true }

          context 'when there are two or more errors' do
            before do
              issue.errors.add(:base, 'a spam error')
              issue.errors.add(:base, 'some other error')
            end

            it 'returns false' do
              expect(issue.render_recaptcha?).to eq(false)
            end
          end

          context 'when there are less than two errors' do
            before do
              issue.errors.add(:base, 'a spam error')
            end

            context 'when spammable does not need recaptcha' do
              before do
                issue.needs_recaptcha = false
              end

              it 'returns false' do
                expect(issue.render_recaptcha?).to eq(false)
              end
            end

            context 'when spammable needs recaptcha' do
              before do
                issue.needs_recaptcha!
              end

              it 'returns false' do
                expect(issue.render_recaptcha?).to eq(true)
              end
            end
          end
        end
      end

      describe '#clear_spam_flags!' do
        it 'clears spam and recaptcha flags' do
          issue.spam = true
          issue.needs_recaptcha = true

          issue.clear_spam_flags!

          expect(issue).not_to be_spam
          expect(issue.needs_recaptcha).to be_falsey
        end
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
