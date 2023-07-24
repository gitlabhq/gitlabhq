# frozen_string_literal: true

RSpec.shared_examples 'known sign in' do
  def stub_remote_ip(ip)
    request.remote_ip = ip
  end

  def stub_user_ip(ip)
    user.update!(current_sign_in_ip: ip)
  end

  def stub_cookie(value = user.id, expires = KnownSignIn::KNOWN_SIGN_IN_COOKIE_EXPIRY)
    cookies.encrypted[KnownSignIn::KNOWN_SIGN_IN_COOKIE] = { value: value, expires: expires }
  end

  context 'when the remote IP and the last sign in IP match' do
    before do
      stub_user_ip('169.0.0.1')
      stub_remote_ip('169.0.0.1')
    end

    it 'does not notify the user' do
      expect(NotificationService).not_to receive(:new)

      post_action
    end

    it 'sets/updates the encrypted cookie' do
      post_action

      expect(cookies.encrypted[KnownSignIn::KNOWN_SIGN_IN_COOKIE]).to eq(user.id)
    end
  end

  context 'when the remote IP and the last sign in IP do not match' do
    before do
      stub_user_ip('127.0.0.1')
      stub_remote_ip('169.0.0.1')
    end

    context 'when the cookie is not previously set' do
      it 'notifies the user' do
        expect_next_instance_of(NotificationService) do |instance|
          expect(instance).to receive(:unknown_sign_in)
        end

        post_action
      end

      it 'sets the encrypted cookie' do
        post_action

        expect(cookies.encrypted[KnownSignIn::KNOWN_SIGN_IN_COOKIE]).to eq(user.id)
      end
    end

    it 'notifies the user when the cookie is expired' do
      stub_cookie(user.id, 1.day.ago)

      expect_next_instance_of(NotificationService) do |instance|
        expect(instance).to receive(:unknown_sign_in)
      end

      post_action
    end

    context 'when notify_on_unknown_sign_in global setting is false' do
      before do
        stub_application_setting(notify_on_unknown_sign_in: false)
      end

      it 'does not notify the user' do
        expect(NotificationService).not_to receive(:new)

        post_action
      end

      it 'does not set a cookie' do
        post_action

        expect(cookies.encrypted[KnownSignIn::KNOWN_SIGN_IN_COOKIE]).to be_nil
      end
    end

    it 'notifies the user when the cookie is for another user' do
      stub_cookie(create(:user).id)

      expect_next_instance_of(NotificationService) do |instance|
        expect(instance).to receive(:unknown_sign_in)
      end

      post_action
    end

    it 'does not notify the user when remote IP matches an active session' do
      ActiveSession.set(user, request)

      expect(NotificationService).not_to receive(:new)

      post_action
    end

    it 'does not notify the user when the cookie is present and not expired' do
      stub_cookie

      expect(NotificationService).not_to receive(:new)

      post_action
    end
  end
end
