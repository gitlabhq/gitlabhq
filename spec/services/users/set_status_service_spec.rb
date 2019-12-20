# frozen_string_literal: true

require 'spec_helper'

describe Users::SetStatusService do
  let(:current_user) { create(:user) }

  subject(:service) { described_class.new(current_user, params) }

  describe '#execute' do
    context 'when params are set' do
      let(:params) { { emoji: 'taurus', message: 'a random status' } }

      it 'creates a status' do
        service.execute

        expect(current_user.status.emoji).to eq('taurus')
        expect(current_user.status.message).to eq('a random status')
      end

      it 'updates a status if it already existed' do
        create(:user_status, user: current_user)

        expect { service.execute }.not_to change { UserStatus.count }
        expect(current_user.status.message).to eq('a random status')
      end

      context 'for another user' do
        let(:target_user) { create(:user) }
        let(:params) do
          { emoji: 'taurus', message: 'a random status', user: target_user }
        end

        context 'the current user is admin' do
          let(:current_user) { create(:admin) }

          it 'changes the status when the current user is allowed to do that' do
            expect { service.execute }.to change { target_user.status }
          end
        end

        it 'does not update the status if the current user is not allowed' do
          expect { service.execute }.not_to change { target_user.status }
        end
      end
    end

    context 'without params' do
      let(:params) { {} }

      it 'deletes the status' do
        status = create(:user_status, user: current_user)

        expect { service.execute }
          .to change { current_user.reload.status }.from(status).to(nil)
      end
    end
  end
end
