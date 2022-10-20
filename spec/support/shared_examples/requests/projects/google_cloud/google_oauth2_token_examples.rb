# frozen_string_literal: true

RSpec.shared_examples 'requires valid Google Oauth2 token' do
  context 'when a valid Google OAuth2 token does not exist' do
    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    it 'triggers Google OAuth2 flow on request' do
      subject

      expect(response).to redirect_to(assigns(:authorize_url))
    end

    context 'and a valid Google OAuth2 token gets created' do
      before do
        allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
          allow(client).to receive(:validate_token).and_return(true)
          allow(client).to receive(:list_projects).and_return(mock_gcp_projects) if mock_gcp_projects
          allow(client).to receive(:create_cloudsql_instance)
        end

        allow_next_instance_of(BranchesFinder) do |finder|
          allow(finder).to receive(:execute).and_return(mock_branches) if mock_branches
        end

        allow_next_instance_of(TagsFinder) do |finder|
          allow(finder).to receive(:execute).and_return(mock_branches) if mock_branches
        end
      end

      it 'renders template as expected' do
        if renders_template
          subject
          expect(response).to render_template(renders_template)
        end
      end

      it 'redirects as expected' do
        if redirects_to
          subject
          expect(response).to redirect_to(redirects_to)
        end
      end
    end
  end
end
