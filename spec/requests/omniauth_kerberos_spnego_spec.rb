require 'spec_helper'
require 'omniauth/strategies/kerberos_spnego'

describe 'OmniAuth Kerberos SPNEGO', lib: true do
  let(:path) { '/users/auth/kerberos_spnego/negotiate' }
  let(:controller_class) { OmniauthKerberosSpnegoController }

  before do
    # In production user_kerberos_spnego_omniauth_callback_path is defined
    # dynamically early when the app boots. Because this is hard to set up
    # during testing we stub out this path helper on the controller.
    allow_any_instance_of(controller_class).to receive(:user_kerberos_spnego_omniauth_callback_path).
      and_return(OmniAuth::Strategies::KerberosSpnego.new(:app).callback_path)
  end

  it 'asks for an SPNEGO token' do
    get path

    expect(response.status).to eq(401)
    expect(response.header['Www-Authenticate']).to eq('Negotiate')
  end

  context 'when an SPNEGO token is provided' do
    it 'passes the token to spnego_negotiate!' do
      expect_any_instance_of(controller_class).to receive(:spnego_credentials!).
        with('fake spnego token')

      get path, {}, spnego_header
    end
  end

  context 'when the final SPNEGO token is provided' do
    before do
      expect_any_instance_of(controller_class).to receive(:spnego_credentials!).
        with('fake spnego token').and_return('janedoe@EXAMPLE.COM')
    end

    it 'redirects to the omniauth callback' do
      get path, {}, spnego_header

      expect(response).to redirect_to('/users/auth/kerberos_spnego/callback')
    end

    it 'stores the users principal name in the session' do
      get path, {}, spnego_header

      expect(session[:kerberos_spnego_principal_name]).to eq('janedoe@EXAMPLE.COM')
    end

    it 'send the final SPNEGO response' do
      allow_any_instance_of(controller_class).to receive(:spnego_response_token).
        and_return("it's the final token")

      get path, {}, spnego_header

      expect(response.header['Www-Authenticate']).to eq(
        "Negotiate #{Base64.strict_encode64("it's the final token")}"
      )
    end
  end

  def spnego_header
    { 'HTTP_AUTHORIZATION' => "Negotiate #{Base64.strict_encode64('fake spnego token')}" }
  end
end
