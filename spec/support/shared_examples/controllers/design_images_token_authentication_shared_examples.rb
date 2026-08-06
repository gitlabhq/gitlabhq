# frozen_string_literal: true

# Token (sessionless) authentication behavior shared by the design
# management image endpoints. The including context must define:
# - `show_design`: a subject performing the GET, merging `token_headers`
#   into the request headers and `token_params` into the request params
# - `token_headers`: the headers carrying the token, defaulting to
#   `{ 'PRIVATE-TOKEN' => personal_access_token.token }`
# - `token_params`: extra request params, defaulting to `{}` (tokens in
#   query parameters must never authenticate design image requests)
# - `personal_access_token`: the token sent by default
# - `viewer`: a user who is allowed to read the design
# - `project`: the private project containing the design
RSpec.shared_examples 'design image accessible with token authentication' do
  context 'when the token has the read_api scope' do
    let(:personal_access_token) { create(:personal_access_token, user: viewer, scopes: [:read_api]) }

    it 'serves the image' do
      show_design

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  context 'when the token is expired' do
    let(:personal_access_token) { create(:personal_access_token, :expired, user: viewer) }

    it 'does not authenticate the user' do
      show_design

      expect(response).to have_gitlab_http_status(:found)
      expect(response.location).to end_with('/users/sign_in')
    end
  end

  context 'when the token is revoked' do
    let(:personal_access_token) { create(:personal_access_token, :revoked, user: viewer) }

    it 'does not authenticate the user' do
      show_design

      expect(response).to have_gitlab_http_status(:found)
      expect(response.location).to end_with('/users/sign_in')
    end
  end

  context 'when the token has an insufficient scope' do
    let(:personal_access_token) { create(:personal_access_token, user: viewer, scopes: [:read_user]) }

    it 'does not authenticate the user' do
      show_design

      expect(response).to have_gitlab_http_status(:found)
      expect(response.location).to end_with('/users/sign_in')
    end
  end

  # Granular tokens skip the coarse api/read_api scope check; their
  # enforcement comes from authorize_granular_token!, which requires
  # read_design on the project for the :design format. read_design is
  # granted through the Work Item: Read assignable permission.
  context 'when the token is a granular personal access token' do
    context 'with a scope granting read_design on the project' do
      let(:personal_access_token) do
        create(:granular_pat, user: viewer, boundary: ::Authz::Boundary.for(project), permissions: :read_work_item)
      end

      it 'serves the image' do
        show_design

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with a scope granting only an unrelated permission on the project' do
      let(:personal_access_token) do
        create(:granular_pat, user: viewer, boundary: ::Authz::Boundary.for(project), permissions: :read_release)
      end

      it 'denies the request' do
        show_design

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'without any scope' do
      let(:personal_access_token) { create(:granular_pat, user: viewer) }

      it 'denies the request' do
        show_design

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  # Project and group access tokens belong to bot users, which
  # `RequestAuthenticator#can_sign_in_bot?` only signs in for API and
  # archive requests - intentionally not design images, matching release
  # downloads.
  context 'when the token is a project or group access token (bot user)' do
    let(:project_bot) { create(:user, :project_bot, developer_of: project) }
    let(:personal_access_token) { create(:personal_access_token, user: project_bot) }

    it 'does not authenticate the bot user' do
      show_design

      expect(response).to have_gitlab_http_status(:found)
      expect(response.location).to end_with('/users/sign_in')
    end
  end

  context 'when the token user does not have permission' do
    let(:personal_access_token) { create(:personal_access_token) }

    it 'does not serve the image' do
      show_design

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when no token is provided' do
    let(:token_headers) { {} }

    it 'does not authenticate the user' do
      show_design

      expect(response).to have_gitlab_http_status(:found)
      expect(response.location).to end_with('/users/sign_in')
    end
  end

  # Tokens are only accepted from headers: a token in the query string
  # leaks into request logs and browser history, so it must not
  # authenticate - not even when a valid header token is also present.
  context 'when the token is passed as a query parameter' do
    let(:token_headers) { {} }
    let(:token_params) { { private_token: personal_access_token.token } }

    it 'does not authenticate the user' do
      show_design

      expect(response).to have_gitlab_http_status(:found)
      expect(response.location).to end_with('/users/sign_in')
    end

    context 'when a valid header token is also present' do
      let(:token_headers) { { 'PRIVATE-TOKEN' => personal_access_token.token } }
      let(:token_params) { { private_token: 'irrelevant' } }

      it 'fails closed and does not authenticate the user' do
        show_design

        expect(response).to have_gitlab_http_status(:found)
        expect(response.location).to end_with('/users/sign_in')
      end
    end
  end

  # The :design format authenticates exclusively through
  # `find_user_from_web_access_token`: sessionless token types accepted
  # elsewhere - feed tokens, static object tokens, and CI job tokens -
  # must never authenticate design image requests.
  #
  # `viewer` is a frozen let_it_be fixture and these tokens lazily
  # generate and save on first read, so read them off a fresh instance.
  context 'when a feed token is provided' do
    let(:token_headers) { {} }
    let(:token_params) { { feed_token: User.find(viewer.id).feed_token } }

    it 'does not authenticate the user' do
      show_design

      expect(response).to have_gitlab_http_status(:found)
      expect(response.location).to end_with('/users/sign_in')
    end
  end

  context 'when a static object token is provided' do
    let(:token_headers) { {} }
    let(:token_params) { { token: User.find(viewer.id).static_object_token } }

    it 'does not authenticate the user' do
      show_design

      expect(response).to have_gitlab_http_status(:found)
      expect(response.location).to end_with('/users/sign_in')
    end
  end

  context 'when a CI job token is provided' do
    let(:job) { create(:ci_build, :running, user: viewer, project: project) }
    let(:token_headers) { {} }
    let(:token_params) { { job_token: job.token } }

    it 'does not authenticate the user' do
      show_design

      expect(response).to have_gitlab_http_status(:found)
      expect(response.location).to end_with('/users/sign_in')
    end
  end
end
