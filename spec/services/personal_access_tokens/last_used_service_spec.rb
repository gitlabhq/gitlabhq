# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::LastUsedService do
  describe '#execute' do
    subject { described_class.new(personal_access_token).execute }

    context 'when the personal access token has not been used recently' do
      let_it_be(:personal_access_token) { create(:personal_access_token, last_used_at: 1.year.ago) }

      it 'updates the last_used_at timestamp' do
        expect { subject }.to change { personal_access_token.last_used_at }
      end

      it 'does not run on read-only GitLab instances' do
        allow(::Gitlab::Database.main).to receive(:read_only?).and_return(true)

        expect { subject }.not_to change { personal_access_token.last_used_at }
      end
    end

    context 'when the personal access token has been used recently' do
      let_it_be(:personal_access_token) { create(:personal_access_token, last_used_at: 1.minute.ago) }

      it 'does not update the last_used_at timestamp' do
        expect { subject }.not_to change { personal_access_token.last_used_at }
      end
    end

    context 'when the last_used_at timestamp is nil' do
      let_it_be(:personal_access_token) { create(:personal_access_token, last_used_at: nil) }

      it 'updates the last_used_at timestamp' do
        expect { subject }.to change { personal_access_token.last_used_at }
      end
    end

    context 'when not a personal access token' do
      let_it_be(:personal_access_token) { create(:oauth_access_token) }

      it 'does not execute' do
        expect(subject).to be_nil
      end
    end
  end
end
