require 'spec_helper'

describe ChatNames::FindUserService, services: true do
  describe '#execute' do
    let(:service) { create(:service) }

    subject { described_class.new(service, params).execute }

    context 'find user mapping' do
      let(:user) { create(:user) }
      let!(:chat_name) { create(:chat_name, user: user, service: service) }

      context 'when existing user is requested' do
        let(:params) { { team_id: chat_name.team_id, user_id: chat_name.chat_id } }

        it 'returns existing user' do
          is_expected.to eq(user)
        end

        it 'updates when last time chat name was used' do
          subject

          expect(chat_name.reload.used_at).to be_like_time(Time.now)
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
