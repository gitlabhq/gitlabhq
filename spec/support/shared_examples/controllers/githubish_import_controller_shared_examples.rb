# frozen_string_literal: true

# Specifications for behavior common to all objects with an email attribute.
# Takes a list of email-format attributes and requires:
# - subject { "the object with a attribute= setter"  }
#   Note: You have access to `email_value` which is the email address value
#         being currently tested).

def assign_session_token(provider)
  session[:"#{provider}_access_token"] = 'asdasd12345'
end

RSpec.shared_examples 'a GitHub-ish import controller: POST personal_access_token' do
  let(:status_import_url) { public_send("status_import_#{provider}_url") }

  it "updates access token" do
    token = 'asdfasdf9876'

    allow_any_instance_of(Gitlab::LegacyGithubImport::Client)
      .to receive(:user).and_return(true)

    post :personal_access_token, params: { personal_access_token: token }

    expect(session[:"#{provider}_access_token"]).to eq(token)
    expect(controller).to redirect_to(status_import_url)
  end

  it "strips access token with spaces" do
    token = 'asdfasdf9876'

    allow_any_instance_of(Gitlab::LegacyGithubImport::Client)
      .to receive(:user).and_return(true)

    post :personal_access_token, params: { personal_access_token: "  #{token} " }

    expect(session[:"#{provider}_access_token"]).to eq(token)
    expect(controller).to redirect_to(status_import_url)
  end

  it 'passes namespace_id param as query param if it was present' do
    namespace_id = 5
    status_import_url = public_send("status_import_#{provider}_url", { namespace_id: namespace_id })

    allow_next_instance_of(Gitlab::LegacyGithubImport::Client) do |client|
      allow(client).to receive(:user).and_return(true)
    end

    post :personal_access_token, params: { personal_access_token: 'some-token', namespace_id: 5 }

    expect(controller).to redirect_to(status_import_url)
  end
end

RSpec.shared_examples 'a GitHub-ish import controller: GET new' do
  let(:status_import_url) { public_send("status_import_#{provider}_url") }

  it "redirects to status if we already have a token" do
    assign_session_token(provider)
    allow(controller).to receive(:logged_in_with_provider?).and_return(false)

    get :new

    expect(controller).to redirect_to(status_import_url)
  end

  it "renders the :new page if no token is present in session" do
    get :new

    expect(response).to render_template(:new)
  end
end

RSpec.shared_examples 'a GitHub-ish import controller: GET status' do
  let(:repo_fake) { Struct.new(:id, :login, :full_name, :name, :owner, keyword_init: true) }
  let(:new_import_url) { public_send("new_import_#{provider}_url") }
  let(:user) { create(:user) }
  let(:repo) { repo_fake.new(login: 'vim', full_name: 'asd/vim', name: 'vim', owner: { login: 'owner' }) }
  let(:org) { double('org', login: 'company') }
  let(:org_repo) { repo_fake.new(login: 'company', full_name: 'company/repo', name: 'repo', owner: { login: 'owner' }) }

  before do
    assign_session_token(provider)
  end

  it "returns variables for json request" do
    project = create(:project, import_type: provider, namespace: user.namespace, import_status: :finished, import_source: 'example/repo')
    group = create(:group)
    group.add_owner(user)
    stub_client(repos: [repo, org_repo], orgs: [org], org_repos: [org_repo], each_page: [double('client', objects: [repo, org_repo])].to_enum)

    get :status, format: :json

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.dig("imported_projects", 0, "id")).to eq(project.id)
    expect(json_response.dig("provider_repos", 0, "id")).to eq(repo.id)
    expect(json_response.dig("provider_repos", 1, "id")).to eq(org_repo.id)
  end

  it "touches the etag cache store" do
    stub_client(repos: [], orgs: [], each_page: [])

    expect_next_instance_of(Gitlab::EtagCaching::Store) do |store|
      expect(store).to receive(:touch) { "realtime_changes_import_#{provider}_path" }
    end

    get :status, format: :json
  end

  it "handles an invalid access token" do
    client = stub_client(repos: [], orgs: [], each_page: [])

    allow(client).to receive(:repos).and_raise(Octokit::Unauthorized)
    allow(client).to receive(:each_page).and_raise(Octokit::Unauthorized)

    get :status

    expect(session[:"#{provider}_access_token"]).to be_nil
    expect(controller).to redirect_to(new_import_url)
    expect(flash[:alert]).to eq("Access denied to your #{Gitlab::ImportSources.title(provider.to_s)} account.")
  end

  it "does not produce N+1 database queries" do
    stub_client(repos: [repo], orgs: [], each_page: [].to_enum)
    group_a = create(:group)
    group_a.add_owner(user)
    create(:project, :import_started, import_type: provider, namespace: user.namespace)

    control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      get :status, format: :json
    end

    stub_client(repos: [repo, org_repo], orgs: [])
    group_b = create(:group)
    group_b.add_owner(user)
    create(:project, :import_started, import_type: provider, namespace: user.namespace)

    expect { get :status, format: :json }
      .not_to exceed_all_query_limit(control)
  end

  context 'when user is not allowed to import projects' do
    let(:user) { create(:user) }
    let!(:group) { create(:group, developers: user) }

    it 'returns 404' do
      expect(stub_client(repos: [], orgs: [])).to receive(:repos)

      get :status, params: { namespace_id: group.id }, format: :html

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when filtering' do
    let(:repo_2) { repo_fake.new(login: 'emacs', full_name: 'asd/emacs', name: 'emacs', owner: { login: 'owner' }) }
    let(:project) { create(:project, import_type: provider, namespace: user.namespace, import_status: :finished, import_source: 'example/repo') }
    let(:group) { create(:group) }
    let(:repos) { [repo, repo_2, org_repo] }

    before do
      group.add_owner(user)
      client = stub_client(repos: repos, orgs: [org], org_repos: [org_repo])
      allow(client).to receive(:each_page).and_return([double('client', objects: repos)].to_enum)
    end

    it 'filters list of repositories by name' do
      get :status, params: { filter: 'emacs' }, format: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response["imported_projects"].count).to eq(0)
      expect(json_response["provider_repos"].count).to eq(1)
      expect(json_response.dig("provider_repos", 0, "id")).to eq(repo_2.id)
    end

    it 'filters the list, ignoring the case of the name' do
      get :status, params: { filter: 'EMACS' }, format: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response["imported_projects"].count).to eq(0)
      expect(json_response["provider_repos"].count).to eq(1)
      expect(json_response.dig("provider_repos", 0, "id")).to eq(repo_2.id)
    end

    context 'when user input contains html' do
      let(:expected_filter) { 'test' }
      let(:filter) { "<html>#{expected_filter}</html>" }

      it 'sanitizes user input' do
        get :status, params: { filter: filter }, format: :json

        expect(assigns(:filter)).to eq(expected_filter)
      end
    end

    context 'when the client returns a non-string name' do
      before do
        repos = [build(:project, name: 2, path: 'test')]

        client = stub_client(repos: repos)
        allow(client).to receive(:each_page).and_return([double('client', objects: repos)].to_enum)
      end

      it 'does not raise an error' do
        get :status, params: { filter: '2' }, format: :json

        expect(response).to have_gitlab_http_status :ok

        expect(json_response["provider_repos"].count).to eq(1)
      end
    end

    context 'when namespace_id query param is provided' do
      let_it_be(:current_user) { create(:user) }

      let(:namespace) { create(:namespace) }

      before do
        allow(controller).to receive(:current_user).and_return(current_user)
      end

      context 'when user is allowed to create projects in this namespace' do
        before do
          allow(current_user).to receive(:can?).and_return(true)
        end

        it 'provides namespace to the template' do
          get :status, params: { namespace_id: namespace.id }, format: :html

          expect(response).to have_gitlab_http_status :ok
          expect(assigns(:namespace)).to eq(namespace)
        end
      end

      context 'when user is not allowed to create projects in this namespace' do
        before do
          allow(current_user).to receive(:can?).and_return(false)
        end

        it 'renders 404' do
          get :status, params: { namespace_id: namespace.id }, format: :html

          expect(response).to have_gitlab_http_status :not_found
        end
      end
    end
  end
end

RSpec.shared_examples 'a GitHub-ish import controller: POST create' do
  let(:user) { create(:user) }
  let(:provider_username) { user.username }
  let(:provider_user) { double('user', login: provider_username) }
  let(:project) { create(:project, import_type: provider, import_status: :finished, import_source: "#{provider_username}/vim") }
  let(:provider_repo) do
    {
      name: 'vim',
      full_name: "#{provider_username}/vim",
      owner: double('owner', login: provider_username)
    }
  end

  before do
    stub_client(user: provider_user, repo: provider_repo, repository: provider_repo)
    assign_session_token(provider)
  end

  it 'returns 200 response when the project is imported successfully' do
    allow(Gitlab::LegacyGithubImport::ProjectCreator)
      .to receive(:new).with(provider_repo, provider_repo[:name], user.namespace, user, type: provider, **access_params)
      .and_return(double(execute: project))

    post :create, params: { target_namespace: user.namespace }, format: :json

    expect(response).to have_gitlab_http_status(:ok)
  end

  it 'returns 422 response with the base error when the project could not be imported' do
    project = build(:project)
    project.errors.add(:name, 'is invalid')
    project.errors.add(:path, 'is old')

    allow(Gitlab::LegacyGithubImport::ProjectCreator)
      .to receive(:new).with(provider_repo, provider_repo[:name], user.namespace, user, type: provider, **access_params)
      .and_return(double(execute: project))

    post :create, params: { target_namespace: user.namespace_path }, format: :json

    expect(response).to have_gitlab_http_status(:unprocessable_entity)
    expect(json_response['errors']).to eq('Name is invalid, Path is old')
  end

  it "touches the etag cache store" do
    allow(Gitlab::LegacyGithubImport::ProjectCreator)
      .to receive(:new).with(provider_repo, provider_repo[:name], user.namespace, user, type: provider, **access_params)
      .and_return(double(execute: project))
    expect_next_instance_of(Gitlab::EtagCaching::Store) do |store|
      expect(store).to receive(:touch) { "realtime_changes_import_#{provider}_path" }
    end

    post :create, params: { target_namespace: user.namespace_path }, format: :json
  end

  context "when the repository owner is the provider user" do
    context "when the provider user and GitLab user's usernames match" do
      it "takes the current user's namespace" do
        expect(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, provider_repo[:name], user.namespace, user, type: provider, **access_params)
          .and_return(double(execute: project))

        post :create, params: { target_namespace: user.namespace_path }, format: :json
      end
    end

    context "when the provider user and GitLab user's usernames don't match" do
      let(:provider_username) { "someone_else" }

      it "takes the current user's namespace" do
        expect(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, provider_repo[:name], user.namespace, user, type: provider, **access_params)
          .and_return(double(execute: project))

        post :create, params: { target_namespace: user.namespace_path }, format: :json
      end
    end
  end

  context "when the repository owner is not the provider user" do
    let(:provider_username) { "someone_else" }

    before do
      assign_session_token(provider)
    end

    context "when a namespace with the provider user's username already exists" do
      let!(:existing_namespace) { user.namespace }

      context "when the namespace is owned by the GitLab user" do
        before do
          user.update!(username: provider_username)
        end

        it "takes the existing namespace" do
          expect(Gitlab::LegacyGithubImport::ProjectCreator)
            .to receive(:new).with(provider_repo, provider_repo[:name], existing_namespace, user, type: provider, **access_params)
            .and_return(double(execute: project))

          post :create, params: { target_namespace: user.namespace_path }, format: :json
        end
      end

      context "when the namespace is not owned by the GitLab user" do
        it "creates a project using user's namespace" do
          create(:user, username: provider_username)

          expect(Gitlab::LegacyGithubImport::ProjectCreator)
            .to receive(:new).with(provider_repo, provider_repo[:name], user.namespace, user, type: provider, **access_params)
            .and_return(double(execute: project))

          post :create, params: { target_namespace: user.namespace_path }, format: :json
        end
      end
    end

    context "when a namespace with the provider user's username doesn't exist" do
      context "when current user can create namespaces" do
        it "does not create the namespace" do
          expect(Gitlab::LegacyGithubImport::ProjectCreator).not_to receive(:new)

          expect { post :create, params: { target_namespace: provider_repo[:name] }, format: :json }.not_to change { Namespace.count }
        end
      end
    end

    context 'user has chosen a namespace and name for the project' do
      let(:test_namespace) { create(:group, name: 'test_namespace') }
      let(:test_name) { 'test_name' }

      before do
        test_namespace.add_owner(user)
      end

      it 'takes the selected namespace and name' do
        expect(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, test_name, test_namespace, user, type: provider, **access_params)
          .and_return(double(execute: project))

        post :create, params: { target_namespace: test_namespace.name, new_name: test_name }, format: :json
      end
    end

    context 'user has chosen an existing nested namespace and name for the project' do
      let(:parent_namespace) { create(:group, name: 'foo') }
      let(:nested_namespace) { create(:group, name: 'bar', parent: parent_namespace) }
      let(:test_name) { 'test_name' }

      before do
        parent_namespace.add_owner(user)
        nested_namespace.add_owner(user)
      end

      it 'takes the selected namespace and name' do
        expect(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, test_name, nested_namespace, user, type: provider, **access_params)
          .and_return(double(execute: project))

        post :create, params: { target_namespace: nested_namespace.full_path, new_name: test_name }, format: :json
      end
    end

    context 'user has chosen a non-existent nested namespaces and name for the project' do
      let(:test_name) { 'test_name' }

      it 'does not take the selected namespace and name' do
        expect(Gitlab::LegacyGithubImport::ProjectCreator)
          .not_to receive(:new)

        post :create, params: { target_namespace: 'foo/bar', new_name: test_name }, format: :json
      end

      it 'does not create namespaces' do
        expect { post :create, params: { target_namespace: 'foo/bar', new_name: test_name }, format: :json }
          .not_to change { Namespace.count }
      end
    end

    context 'user has chosen existent and non-existent nested namespaces and name for the project' do
      let(:test_name) { 'test_name' }
      let!(:parent_namespace) { create(:group, name: 'foo') }

      before do
        parent_namespace.add_owner(user)
      end

      it 'does not take the selected namespace and name' do
        expect(Gitlab::LegacyGithubImport::ProjectCreator).not_to receive(:new)

        post :create, params: { target_namespace: 'foo/foobar/bar', new_name: test_name }, format: :json
      end

      it 'does not create the namespaces' do
        expect { post :create, params: { target_namespace: 'foo/foobar/bar', new_name: test_name }, format: :json }
          .not_to change { Namespace.count }
      end

      it 'does not create a new namespace under the user namespace' do
        expect(Gitlab::LegacyGithubImport::ProjectCreator).not_to receive(:new)

        expect { post :create, params: { target_namespace: "#{user.namespace_path}/test_group", new_name: test_name }, format: :js }
          .not_to change { Namespace.count }
      end
    end

    context 'user can use a group without having permissions to create a group' do
      let(:test_name) { 'test_name' }
      let!(:group) { create(:group, name: 'foo') }

      it 'takes the selected namespace and name' do
        group.add_owner(user)
        user.update!(can_create_group: false)

        expect(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, test_name, group, user, type: provider, **access_params)
          .and_return(double(execute: project))

        post :create, params: { target_namespace: 'foo', new_name: test_name }, format: :js
      end
    end

    context 'when user can not create projects in the chosen namespace' do
      it 'returns 422 response' do
        other_namespace = create(:group, name: 'other_namespace')

        post :create, params: { target_namespace: other_namespace.name }, format: :json

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end
  end
end

RSpec.shared_examples 'a GitHub-ish import controller: GET realtime_changes' do
  let(:user) { create(:user) }

  before do
    assign_session_token(provider)
  end

  it 'sets a Poll-Interval header' do
    project = create(:project, import_type: provider, namespace: user.namespace, import_status: :finished, import_source: 'example/repo')

    get :realtime_changes

    expect(json_response).to match([a_hash_including({ "id" => project.id, "import_status" => project.import_status })])
    expect(Integer(response.headers['Poll-Interval'])).to be > -1
  end
end
