# Specifications for behavior common to all objects with an email attribute.
# Takes a list of email-format attributes and requires:
# - subject { "the object with a attribute= setter"  }
#   Note: You have access to `email_value` which is the email address value
#         being currently tested).

def assign_session_token(provider)
  session[:"#{provider}_access_token"] = 'asdasd12345'
end

shared_examples 'a GitHub-ish import controller: POST personal_access_token' do
  let(:status_import_url) { public_send("status_import_#{provider}_url") }

  it "updates access token" do
    token = 'asdfasdf9876'

    allow_any_instance_of(Gitlab::LegacyGithubImport::Client)
      .to receive(:user).and_return(true)

    post :personal_access_token, personal_access_token: token

    expect(session[:"#{provider}_access_token"]).to eq(token)
    expect(controller).to redirect_to(status_import_url)
  end
end

shared_examples 'a GitHub-ish import controller: GET new' do
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

shared_examples 'a GitHub-ish import controller: GET status' do
  let(:new_import_url) { public_send("new_import_#{provider}_url") }
  let(:user) { create(:user) }
  let(:repo) { OpenStruct.new(login: 'vim', full_name: 'asd/vim') }
  let(:org) { OpenStruct.new(login: 'company') }
  let(:org_repo) { OpenStruct.new(login: 'company', full_name: 'company/repo') }
  let(:extra_assign_expectations) { {} }

  before do
    assign_session_token(provider)
  end

  it "assigns variables" do
    project = create(:project, import_type: provider, creator_id: user.id)
    stub_client(repos: [repo, org_repo], orgs: [org], org_repos: [org_repo])

    get :status

    expect(assigns(:already_added_projects)).to eq([project])
    expect(assigns(:repos)).to eq([repo, org_repo])
    extra_assign_expectations.each do |key, value|
      expect(assigns(key)).to eq(value)
    end
  end

  it "does not show already added project" do
    project = create(:project, import_type: provider, creator_id: user.id, import_source: 'asd/vim')
    stub_client(repos: [repo], orgs: [])

    get :status

    expect(assigns(:already_added_projects)).to eq([project])
    expect(assigns(:repos)).to eq([])
  end

  it "handles an invalid access token" do
    allow_any_instance_of(Gitlab::LegacyGithubImport::Client)
      .to receive(:repos).and_raise(Octokit::Unauthorized)

    get :status

    expect(session[:"#{provider}_access_token"]).to be_nil
    expect(controller).to redirect_to(new_import_url)
    expect(flash[:alert]).to eq("Access denied to your #{Gitlab::ImportSources.title(provider.to_s)} account.")
  end
end

shared_examples 'a GitHub-ish import controller: POST create' do
  let(:user) { create(:user) }
  let(:provider_username) { user.username }
  let(:provider_user) { OpenStruct.new(login: provider_username) }
  let(:provider_repo) do
    OpenStruct.new(
      name: 'vim',
      full_name: "#{provider_username}/vim",
      owner: OpenStruct.new(login: provider_username)
    )
  end

  before do
    stub_client(user: provider_user, repo: provider_repo)
    assign_session_token(provider)
  end

  context "when the repository owner is the provider user" do
    context "when the provider user and GitLab user's usernames match" do
      it "takes the current user's namespace" do
        expect(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, provider_repo.name, user.namespace, user, access_params, type: provider)
            .and_return(double(execute: true))

        post :create, format: :js
      end
    end

    context "when the provider user and GitLab user's usernames don't match" do
      let(:provider_username) { "someone_else" }

      it "takes the current user's namespace" do
        expect(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, provider_repo.name, user.namespace, user, access_params, type: provider)
            .and_return(double(execute: true))

        post :create, format: :js
      end
    end
  end

  context "when the repository owner is not the provider user" do
    let(:other_username) { "someone_else" }

    before do
      provider_repo.owner = OpenStruct.new(login: other_username)
      assign_session_token(provider)
    end

    context "when a namespace with the provider user's username already exists" do
      let!(:existing_namespace) { user.namespace }

      context "when the namespace is owned by the GitLab user" do
        before do
          user.username = other_username
          user.save
        end

        it "takes the existing namespace" do
          expect(Gitlab::LegacyGithubImport::ProjectCreator)
            .to receive(:new).with(provider_repo, provider_repo.name, existing_namespace, user, access_params, type: provider)
              .and_return(double(execute: true))

          post :create, format: :js
        end
      end

      context "when the namespace is not owned by the GitLab user" do
        it "creates a project using user's namespace" do
          create(:user, username: other_username)

          expect(Gitlab::LegacyGithubImport::ProjectCreator)
            .to receive(:new).with(provider_repo, provider_repo.name, user.namespace, user, access_params, type: provider)
              .and_return(double(execute: true))

          post :create, format: :js
        end
      end
    end

    context "when a namespace with the provider user's username doesn't exist" do
      context "when current user can create namespaces" do
        it "creates the namespace" do
          expect(Gitlab::LegacyGithubImport::ProjectCreator)
            .to receive(:new).and_return(double(execute: true))

          expect { post :create, target_namespace: provider_repo.name, format: :js }.to change(Namespace, :count).by(1)
        end

        it "takes the new namespace" do
          expect(Gitlab::LegacyGithubImport::ProjectCreator)
            .to receive(:new).with(provider_repo, provider_repo.name, an_instance_of(Group), user, access_params, type: provider)
              .and_return(double(execute: true))

          post :create, target_namespace: provider_repo.name, format: :js
        end
      end

      context "when current user can't create namespaces" do
        before do
          user.update_attribute(:can_create_group, false)
        end

        it "doesn't create the namespace" do
          expect(Gitlab::LegacyGithubImport::ProjectCreator)
            .to receive(:new).and_return(double(execute: true))

          expect { post :create, format: :js }.not_to change(Namespace, :count)
        end

        it "takes the current user's namespace" do
          expect(Gitlab::LegacyGithubImport::ProjectCreator)
            .to receive(:new).with(provider_repo, provider_repo.name, user.namespace, user, access_params, type: provider)
              .and_return(double(execute: true))

          post :create, format: :js
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
          .to receive(:new).with(provider_repo, test_name, test_namespace, user, access_params, type: provider)
            .and_return(double(execute: true))

        post :create, { target_namespace: test_namespace.name, new_name: test_name, format: :js }
      end

      it 'takes the selected name and default namespace' do
        expect(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, test_name, user.namespace, user, access_params, type: provider)
            .and_return(double(execute: true))

        post :create, { new_name: test_name, format: :js }
      end
    end

    context 'user has chosen an existing nested namespace and name for the project', :postgresql do
      let(:parent_namespace) { create(:group, name: 'foo', owner: user) }
      let(:nested_namespace) { create(:group, name: 'bar', parent: parent_namespace) }
      let(:test_name) { 'test_name' }

      before do
        nested_namespace.add_owner(user)
      end

      it 'takes the selected namespace and name' do
        expect(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, test_name, nested_namespace, user, access_params, type: provider)
            .and_return(double(execute: true))

        post :create, { target_namespace: nested_namespace.full_path, new_name: test_name, format: :js }
      end
    end

    context 'user has chosen a non-existent nested namespaces and name for the project', :postgresql do
      let(:test_name) { 'test_name' }

      it 'takes the selected namespace and name' do
        expect(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, test_name, kind_of(Namespace), user, access_params, type: provider)
            .and_return(double(execute: true))

        post :create, { target_namespace: 'foo/bar', new_name: test_name, format: :js }
      end

      it 'creates the namespaces' do
        allow(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, test_name, kind_of(Namespace), user, access_params, type: provider)
            .and_return(double(execute: true))

        expect { post :create, { target_namespace: 'foo/bar', new_name: test_name, format: :js } }
          .to change { Namespace.count }.by(2)
      end

      it 'new namespace has the right parent' do
        allow(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, test_name, kind_of(Namespace), user, access_params, type: provider)
            .and_return(double(execute: true))

        post :create, { target_namespace: 'foo/bar', new_name: test_name, format: :js }

        expect(Namespace.find_by_path_or_name('bar').parent.path).to eq('foo')
      end
    end

    context 'user has chosen existent and non-existent nested namespaces and name for the project', :postgresql do
      let(:test_name) { 'test_name' }
      let!(:parent_namespace) { create(:group, name: 'foo', owner: user) }

      before do
        parent_namespace.add_owner(user)
      end

      it 'takes the selected namespace and name' do
        expect(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, test_name, kind_of(Namespace), user, access_params, type: provider)
            .and_return(double(execute: true))

        post :create, { target_namespace: 'foo/foobar/bar', new_name: test_name, format: :js }
      end

      it 'creates the namespaces' do
        allow(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, test_name, kind_of(Namespace), user, access_params, type: provider)
            .and_return(double(execute: true))

        expect { post :create, { target_namespace: 'foo/foobar/bar', new_name: test_name, format: :js } }
          .to change { Namespace.count }.by(2)
      end

      it 'does not create a new namespace under the user namespace' do
        expect(Gitlab::LegacyGithubImport::ProjectCreator)
            .to receive(:new).with(provider_repo, test_name, user.namespace, user, access_params, type: provider)
                    .and_return(double(execute: true))

        expect { post :create, { target_namespace: "#{user.namespace_path}/test_group", new_name: test_name, format: :js } }
            .not_to change { Namespace.count }
      end
    end

    context 'user cannot create a subgroup inside a group is not a member of' do
      let(:test_name) { 'test_name' }
      let!(:parent_namespace) { create(:group, name: 'foo') }

      it 'does not take the selected namespace and name' do
        expect(Gitlab::LegacyGithubImport::ProjectCreator)
            .to receive(:new).with(provider_repo, test_name, user.namespace, user, access_params, type: provider)
                    .and_return(double(execute: true))

        post :create, { target_namespace: 'foo/foobar/bar', new_name: test_name, format: :js }
      end

      it 'does not create the namespaces' do
        allow(Gitlab::LegacyGithubImport::ProjectCreator)
            .to receive(:new).with(provider_repo, test_name, kind_of(Namespace), user, access_params, type: provider)
                    .and_return(double(execute: true))

        expect { post :create, { target_namespace: 'foo/foobar/bar', new_name: test_name, format: :js } }
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
            .to receive(:new).with(provider_repo, test_name, group, user, access_params, type: provider)
                    .and_return(double(execute: true))

        post :create, { target_namespace: 'foo', new_name: test_name, format: :js }
      end
    end
  end
end
