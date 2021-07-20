# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spam::HamService do
  let_it_be(:user) { create(:user) }

  let!(:spam_log) { create(:spam_log, user: user, submitted_as_ham: false) }
  let(:fake_akismet_service) { double(:akismet_service) }

  subject { described_class.new(spam_log) }

  before do
    allow(Spam::AkismetService).to receive(:new).and_return fake_akismet_service
  end

  describe '#execute' do
    context 'AkismetService returns false (Akismet cannot be reached, etc)' do
      before do
        allow(fake_akismet_service).to receive(:submit_ham).and_return false
      end

      it 'returns false' do
        expect(subject.execute).to be_falsey
      end

      it 'does not update the record' do
        expect { subject.execute }.not_to change { spam_log.submitted_as_ham }
      end

      context 'if spam log record has already been marked as spam' do
        before do
          spam_log.update_attribute(:submitted_as_ham, true)
        end

        it 'does not update the record' do
          expect { subject.execute }.not_to change { spam_log.submitted_as_ham }
        end
      end
    end

    context 'Akismet ham submission is successful' do
      before do
        spam_log.update_attribute(:submitted_as_ham, false)
        allow(fake_akismet_service).to receive(:submit_ham).and_return true
      end

      it 'returns true' do
        expect(subject.execute).to be_truthy
      end

      it 'updates the record' do
        expect { subject.execute }.to change { spam_log.submitted_as_ham }.from(false).to(true)
      end
    end
  end
end
