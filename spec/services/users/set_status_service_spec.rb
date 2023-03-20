# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::SetStatusService, feature_category: :user_management do
  let(:current_user) { create(:user) }

  subject(:service) { described_class.new(current_user, params) }

  describe '#execute' do
    shared_examples_for 'bumps user' do
      it 'bumps User#updated_at' do
        expect { service.execute }.to change { current_user.updated_at }
      end
    end

    shared_examples_for 'does not bump user' do
      it 'does not bump User#updated_at' do
        expect { service.execute }.not_to change { current_user.updated_at }
      end
    end

    context 'when params are set' do
      let(:params) { { emoji: 'taurus', message: 'a random status', availability: 'busy' } }

      it 'creates a status' do
        service.execute

        expect(current_user.status.emoji).to eq('taurus')
        expect(current_user.status.message).to eq('a random status')
        expect(current_user.status.availability).to eq('busy')
      end

      it 'updates a status if it already existed' do
        create(:user_status, user: current_user)

        expect { service.execute }.not_to change { UserStatus.count }
        expect(current_user.status.message).to eq('a random status')
      end

      it 'returns true' do
        create(:user_status, user: current_user)
        expect(service.execute).to be(true)
      end

      it_behaves_like 'bumps user'

      context 'when setting availability to not_set' do
        before do
          params[:availability] = 'not_set'

          create(:user_status, user: current_user, availability: 'busy')
        end

        it 'updates the availability' do
          expect { service.execute }.to change { current_user.status.availability }.from('busy').to('not_set')
        end
      end

      context 'when the given availability value is not valid' do
        before do
          params[:availability] = 'not a valid value'
        end

        it 'does not update the status' do
          user_status = create(:user_status, user: current_user)

          expect { service.execute }.not_to change { user_status.reload }
        end
      end

      context 'for another user' do
        let(:target_user) { create(:user) }
        let(:params) do
          { emoji: 'taurus', message: 'a random status', user: target_user }
        end

        context 'the current user is admin', :enable_admin_mode do
          let(:current_user) { create(:admin) }

          it 'changes the status when the current user is allowed to do that' do
            expect { service.execute }.to change { target_user.status }
          end
        end

        it 'does not update the status if the current user is not allowed' do
          expect { service.execute }.not_to change { target_user.status }
        end

        it_behaves_like 'does not bump user'
      end
    end

    context 'without params' do
      let(:params) { {} }

      shared_examples 'removes user status record' do
        it 'deletes the user status record' do
          expect { service.execute }
            .to change { current_user.reload.status }.from(user_status).to(nil)
        end

        it_behaves_like 'bumps user'
      end

      context 'when user has existing user status record' do
        let!(:user_status) { create(:user_status, user: current_user) }

        it_behaves_like 'removes user status record'

        context 'when not_set is given for availability' do
          let(:params) { { availability: 'not_set' } }

          it_behaves_like 'removes user status record'
        end
      end

      context 'when user has no existing user status record' do
        it_behaves_like 'does not bump user'
      end
    end
  end
end
