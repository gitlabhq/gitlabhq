require 'spec_helper'

describe Users::BuildService do
  describe '#execute' do
    let(:params) do
      { name: 'John Doe', username: 'jduser', email: 'jd@example.com', password: 'mydummypass' }
    end

    context 'with an admin user' do
      let(:admin_user) { create(:admin) }
      let(:service) { described_class.new(admin_user, params) }

      it 'returns a valid user' do
        expect(service.execute).to be_valid
      end
    end

    context 'with non admin user' do
      let(:user) { create(:user) }
      let(:service) { described_class.new(user, params) }

      it 'raises AccessDeniedError exception' do
        expect { service.execute }.to raise_error Gitlab::Access::AccessDeniedError
      end
    end

    context 'with nil user' do
      let(:service) { described_class.new(nil, params) }

      it 'returns a valid user' do
        expect(service.execute).to be_valid
      end

      context 'when "send_user_confirmation_email" application setting is true' do
        before do
          stub_application_setting(send_user_confirmation_email: true, signup_enabled?: true)
        end

        it 'does not confirm the user' do
          expect(service.execute).not_to be_confirmed
        end
      end

      context 'when "send_user_confirmation_email" application setting is false' do
        before do
          stub_application_setting(send_user_confirmation_email: false, signup_enabled?: true)
        end

        it 'confirms the user' do
          expect(service.execute).to be_confirmed
        end
      end
    end
  end
end
