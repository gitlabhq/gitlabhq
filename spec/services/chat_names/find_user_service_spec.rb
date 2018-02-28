require 'spec_helper'

describe ChatNames::FindUserService do
  describe '#execute' do
    let(:service) { create(:service) }

    subject { described_class.new(service, params).execute }

    context 'find user mapping' do
      let(:user) { create(:user) }
      let!(:chat_name) { create(:chat_name, user: user, service: service) }

      context 'when existing user is requested' do
        let(:params) { { team_id: chat_name.team_id, user_id: chat_name.chat_id } }

        it 'returns the existing user' do
          is_expected.to eq(user)
        end

        it 'updates when last time chat name was used' do
          expect(chat_name.last_used_at).to be_nil

          subject

          initial_last_used = chat_name.reload.last_used_at
          expect(initial_last_used).to be_present

          Timecop.travel(2.days.from_now) { described_class.new(service, params).execute }

          expect(chat_name.reload.last_used_at).to be > initial_last_used
        end
      end

      context 'when different user is requested' do
        let(:params) { { team_id: chat_name.team_id, user_id: 'non-existing-user' } }

        it 'returns existing user' do
          is_expected.to be_nil
        end
      end
    end
  end
end
