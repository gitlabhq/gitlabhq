# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spam::AkismetMarkAsSpamService, feature_category: :instance_resiliency do
  let(:user_agent_detail) { build(:user_agent_detail) }
  let(:spammable) { build(:issue, user_agent_detail: user_agent_detail) }
  let(:fake_akismet_service) { double(:akismet_service, submit_spam: true) }

  subject { described_class.new(target: spammable) }

  describe '#execute' do
    before do
      allow(subject).to receive(:akismet).and_return(fake_akismet_service)
    end

    context 'when the spammable object is not submittable' do
      before do
        allow(spammable).to receive(:submittable_as_spam?).and_return false
      end

      it 'does not submit as spam' do
        expect(subject.execute).to be_falsey
      end
    end

    context 'spam is submitted successfully' do
      before do
        allow(spammable).to receive(:submittable_as_spam?).and_return true
        allow(fake_akismet_service).to receive(:submit_spam).and_return true
      end

      it 'submits as spam' do
        expect(subject.execute).to be_truthy
      end

      it "updates the spammable object's user agent detail as being submitted as spam" do
        expect(user_agent_detail).to receive(:update_attribute)

        subject.execute
      end

      context 'when Akismet does not consider it spam' do
        it 'does not update the spammable object as spam' do
          allow(fake_akismet_service).to receive(:submit_spam).and_return false

          expect(subject.execute).to be_falsey
        end
      end
    end
  end
end
