# frozen_string_literal: true

RSpec.shared_examples 'requires valid Google OAuth2 configuration' do
  context 'when GitLab instance does not have valid Google OAuth2 configuration ' do
    before do
      project.add_maintainer(user)
      unconfigured_google_oauth2 = Struct.new(:app_id, :app_secret)
                                         .new('', '')
      allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for)
                                                .with('google_oauth2')
                                                .and_return(unconfigured_google_oauth2)
    end

    it 'renders forbidden' do
      sign_in(user)

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end
