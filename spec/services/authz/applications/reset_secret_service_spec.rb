# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Authz::Applications::ResetSecretService, :aggregate_failures, feature_category: :system_access do
  let(:application) { create(:oauth_application) }

  describe '#execute' do
    subject(:service) { described_class.new(application: application, current_user: current_user) }

    context 'as a user' do
      let_it_be(:current_user) { create(:user) }

      it 'does not change the secret' do
        expect { service.execute }.not_to change { application.reload.secret }
      end

      it 'returns an error response' do
        response = service.execute
        expect(response.error?).to be_truthy
        expect(response.message).to include('cannot reset secret')
      end
    end

    context 'as an admin', :enable_admin_mode do
      let_it_be(:current_user) { create(:admin) }

      it 'returns a successful ServiceResponse' do
        response = service.execute
        expect(response).to be_kind_of(ServiceResponse)
        expect(response.success?).to be_truthy
      end

      it 'changes the secret' do
        expect { service.execute }.to change { application.reload.secret }
      end

      context 'when saving fails' do
        before do
          allow(application).to receive(:save).and_return(false)
        end

        it 'does not change the secret' do
          expect { service.execute }.not_to change { application.reload.secret }
        end
      end
    end
  end
end
