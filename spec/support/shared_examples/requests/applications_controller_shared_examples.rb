# frozen_string_literal: true

RSpec.shared_examples 'applications controller - GET #show' do
  describe 'GET #show' do
    it 'renders template' do
      get show_path

      expect(response).to render_template :show
    end

    context 'when application is viewed after being created' do
      before do
        create_application
        stub_feature_flags(hash_oauth_secrets: false)
      end

      it 'sets `@created` instance variable to `true`' do
        get show_path

        expect(assigns[:created]).to eq(true)
      end
    end

    context 'when application is reviewed' do
      before do
        stub_feature_flags(hash_oauth_secrets: false)
      end

      it 'sets `@created` instance variable to `false`' do
        get show_path

        expect(assigns[:created]).to eq(false)
      end
    end
  end
end

RSpec.shared_examples 'applications controller - POST #create' do
  it "sets `#{OauthApplications::CREATED_SESSION_KEY}` session key to `true`" do
    stub_feature_flags(hash_oauth_secrets: false)
    create_application

    expect(session[OauthApplications::CREATED_SESSION_KEY]).to eq(true)
  end
end

def create_application
  create_params = attributes_for(:application, trusted: true, confidential: false, scopes: ['api'])
  post create_path, params: { doorkeeper_application: create_params }
end
