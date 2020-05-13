# frozen_string_literal: true

RSpec.shared_examples 'known sign in' do
  def stub_remote_ip(ip)
    request.remote_ip = ip
  end

  def stub_user_ip(ip)
    user.update!(current_sign_in_ip: ip)
  end

  context 'with a valid post' do
    context 'when remote IP does not match user last sign in IP' do
      before do
        stub_user_ip('127.0.0.1')
        stub_remote_ip('169.0.0.1')
      end

      it 'notifies the user' do
        expect_next_instance_of(NotificationService) do |instance|
          expect(instance).to receive(:unknown_sign_in)
        end

        post_action
      end
    end

    context 'when remote IP matches an active session' do
      before do
        existing_sessions = ActiveSession.session_ids_for_user(user.id)
        existing_sessions.each { |sessions| ActiveSession.destroy(user, sessions) }

        stub_user_ip('169.0.0.1')
        stub_remote_ip('127.0.0.1')

        ActiveSession.set(user, request)
      end

      it 'does not notify the user' do
        expect_any_instance_of(NotificationService).not_to receive(:unknown_sign_in)

        post_action
      end
    end

    context 'when remote IP address matches last sign in IP' do
      before do
        stub_user_ip('127.0.0.1')
        stub_remote_ip('127.0.0.1')
      end

      it 'does not notify the user' do
        expect_any_instance_of(NotificationService).not_to receive(:unknown_sign_in)

        post_action
      end
    end
  end
end
