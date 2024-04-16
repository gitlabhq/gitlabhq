# frozen_string_literal: true

RSpec.shared_context 'container registry auth service context' do
  let_it_be(:rsa_key) { OpenSSL::PKey::RSA.generate(3072) }

  let(:current_project) { nil }
  let(:current_user) { nil }
  let(:current_params) { {} }
  let(:payload) { JWT.decode(subject[:token], rsa_key, true, { algorithm: 'RS256' }).first }

  let(:authentication_abilities) do
    [:read_container_image, :create_container_image, :admin_container_image]
  end

  let(:log_data) { { message: 'Denied container registry permissions' } }

  subject do
    described_class.new(current_project, current_user, current_params)
      .execute(authentication_abilities: authentication_abilities)
  end

  before do
    allow(Gitlab.config.registry).to receive_messages(enabled: true, issuer: 'rspec', key: nil)
    allow_next_instance_of(JSONWebToken::RSAToken) do |instance|
      allow(instance).to receive(:key).and_return(rsa_key)
    end
  end
end

RSpec.shared_examples 'an authenticated' do
  it { is_expected.to include(:token) }
  it { expect(payload).to include('access') }
end

RSpec.shared_examples 'a valid token' do
  it { is_expected.to include(:token) }
  it { expect(payload).to include('access') }

  context 'a expirable' do
    let(:expires_at) { Time.zone.at(payload['exp']) }
    let(:expire_delay) { 10 }

    context 'for default configuration' do
      it { expect(expires_at).not_to be_within(2.seconds).of(Time.current + expire_delay.minutes) }
    end

    context 'for changed configuration' do
      before do
        stub_application_setting(container_registry_token_expire_delay: expire_delay)
      end

      it { expect(expires_at).to be_within(2.seconds).of(Time.current + expire_delay.minutes) }
    end
  end
end

RSpec.shared_examples 'with auth_type' do
  let(:current_params) { super().merge(auth_type: :foo) }

  it { expect(payload['auth_type']).to eq('foo') }

  it "contains the auth_type as part of the encoded user information in the payload" do
    user_info = decode_user_info_from_payload(payload)

    expect(user_info["token_type"]).to eq("foo")
  end
end

RSpec.shared_examples 'a browsable' do
  let(:access) do
    [{ 'type' => 'registry',
       'name' => 'catalog',
       'actions' => ['*'] }]
  end

  it_behaves_like 'a valid token'
  it_behaves_like 'not a container repository factory'

  it 'has the correct scope' do
    expect(payload).to include('access' => access)
  end
end

RSpec.shared_examples 'an accessible' do
  let(:access) do
    [{ 'type' => 'repository',
       'name' => project.full_path,
       'actions' => actions,
       'meta' => {
         'project_path' => project.full_path,
         'project_id' => project.id,
         'root_namespace_id' => project.root_ancestor.id
       } }]
  end

  it_behaves_like 'a valid token'

  it 'has the correct scope' do
    expect(payload).to include('access' => access)
  end
end

RSpec.shared_examples 'an inaccessible' do
  it_behaves_like 'a valid token'
  it { expect(payload).to include('access' => []) }
end

RSpec.shared_examples 'a deletable' do
  it_behaves_like 'an accessible' do
    let(:actions) { ['*'] }
  end
end

RSpec.shared_examples 'a deletable since registry 2.7' do
  it_behaves_like 'an accessible' do
    let(:actions) { ['delete'] }
  end
end

RSpec.shared_examples 'a pullable' do
  it_behaves_like 'an accessible' do
    let(:actions) { ['pull'] }
  end
end

RSpec.shared_examples 'a pushable' do
  it_behaves_like 'an accessible' do
    let(:actions) { ['push'] }
  end
end

RSpec.shared_examples 'a pullable and pushable' do
  it_behaves_like 'an accessible' do
    let(:actions) { %w[pull push] }
  end
end

RSpec.shared_examples 'a forbidden' do
  it { is_expected.to include(http_status: 403) }
  it { is_expected.not_to include(:token) }
end

RSpec.shared_examples 'container repository factory' do
  it 'creates a new container repository resource' do
    expect { subject }
      .to change { project.container_repositories.count }.by(1)
  end
end

RSpec.shared_examples 'not a container repository factory' do
  it 'does not create a new container repository resource' do
    expect { subject }.not_to change { ContainerRepository.count }
  end
end

RSpec.shared_examples 'logs an auth warning' do |requested_actions|
  let(:expected) do
    {
      scope_type: 'repository',
      requested_project_path: project.full_path,
      requested_actions: requested_actions,
      authorized_actions: [],
      user_id: current_user&.id,
      username: current_user&.username
    }.compact
  end

  it do
    expect(Gitlab::AuthLogger).to receive(:warn).with(expected.merge!(log_data))

    subject
  end
end

RSpec.shared_examples 'allowed to delete container repository images' do
  let(:authentication_abilities) do
    [:admin_container_image]
  end

  it_behaves_like 'a valid token'

  context 'allow to delete images' do
    let(:current_params) do
      { scopes: ["repository:#{project.full_path}:*"] }
    end

    it_behaves_like 'a deletable'
  end

  context 'allow to delete images since registry 2.7' do
    let(:current_params) do
      { scopes: ["repository:#{project.full_path}:delete"] }
    end

    it_behaves_like 'a deletable since registry 2.7'
  end
end

RSpec.shared_examples 'a container registry auth service' do
  include_context 'container registry auth service context'

  describe '.full_access_token' do
    let_it_be(:project) { create(:project) }

    let(:token) { described_class.full_access_token(project.full_path) }

    subject { { token: token } }

    it_behaves_like 'an accessible' do
      let(:actions) { ['*'] }
    end

    it_behaves_like 'not a container repository factory'
  end

  describe '.import_access_token' do
    let(:access) do
      [{ 'type' => 'registry',
         'name' => 'import',
         'actions' => ['*'] }]
    end

    let(:token) { described_class.import_access_token }

    subject { { token: token } }

    it_behaves_like 'a valid token'
    it_behaves_like 'not a container repository factory'

    it 'has the correct scope' do
      expect(payload).to include('access' => access)
    end
  end

  describe '.pull_access_token' do
    let_it_be(:project) { create(:project) }

    let(:token) { described_class.pull_access_token(project.full_path) }

    subject { { token: token } }

    it_behaves_like 'an accessible' do
      let(:actions) { ['pull'] }
    end

    it_behaves_like 'not a container repository factory'
  end

  describe '.pull_nested_repositories_access_token' do
    let_it_be(:project) { create(:project) }

    let(:token) { described_class.pull_nested_repositories_access_token(project.full_path) }
    let(:access) do
      [
        {
          'type' => 'repository',
          'name' => project.full_path,
          'actions' => ['pull'],
          'meta' => {
            'project_path' => project.full_path,
            'project_id' => project.id,
            'root_namespace_id' => project.root_ancestor.id
          }
        },
        {
          'type' => 'repository',
          'name' => "#{project.full_path}/*",
          'actions' => ['pull'],
          'meta' => {
            'project_path' => project.full_path,
            'project_id' => project.id,
            'root_namespace_id' => project.root_ancestor.id
          }
        }
      ]
    end

    subject { { token: token } }

    it 'has the correct scope' do
      expect(payload).to include('access' => access)
    end

    it_behaves_like 'a valid token'
    it_behaves_like 'not a container repository factory'

    context 'with path ending with a slash' do
      let(:token) { described_class.pull_nested_repositories_access_token("#{project.full_path}/") }

      it 'has the correct scope' do
        expect(payload).to include('access' => access)
      end

      it_behaves_like 'a valid token'
      it_behaves_like 'not a container repository factory'
    end
  end

  describe '.push_pull_nested_repositories_access_token' do
    let_it_be(:project) { create(:project) }
    let(:name) { project.full_path }
    let(:token) { described_class.push_pull_nested_repositories_access_token(name) }
    let(:access) do
      [
        {
          'type' => 'repository',
          'name' => name,
          'actions' => %w[pull push],
          'meta' => { 'project_path' => name }
        },
        {
          'type' => 'repository',
          'name' => "#{name}/*",
          'actions' => %w[pull],
          'meta' => { 'project_path' => name }
        }
      ]
    end

    subject { { token: token } }

    it 'has the correct scope' do
      expect(payload).to include('access' => access)
    end

    it 'sends the name as the override project path for the access token' do
      expect(described_class).to receive(:access_token).with(anything, override_project_path: name)

      subject
    end

    it_behaves_like 'a valid token'
    it_behaves_like 'not a container repository factory'

    context 'with path ending with a slash' do
      let(:token) { described_class.push_pull_nested_repositories_access_token("#{project.full_path}/") }

      it 'has the correct scope' do
        expect(payload).to include('access' => access)
      end

      it_behaves_like 'a valid token'
      it_behaves_like 'not a container repository factory'
    end
  end

  context 'user authorization' do
    let_it_be(:current_user) { create(:user) }

    context 'for registry catalog' do
      let(:current_params) do
        { scopes: ["registry:catalog:*"] }
      end

      context 'disallow browsing for users without GitLab admin rights' do
        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end
    end

    shared_examples 'private project' do
      context 'allow to use scope-less authentication' do
        it_behaves_like 'a valid token'
        it_behaves_like 'with auth_type'
      end

      context 'allow developer to push images' do
        before_all do
          project.add_developer(current_user)
        end

        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:push"] }
        end

        it_behaves_like 'a pushable'
        it_behaves_like 'container repository factory'
        it_behaves_like 'with auth_type'
      end

      context 'disallow developer to delete images' do
        before_all do
          project.add_developer(current_user)
        end

        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:*"] }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'

        it_behaves_like 'logs an auth warning', ['*']
      end

      context 'disallow developer to delete images since registry 2.7' do
        before_all do
          project.add_developer(current_user)
        end

        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:delete"] }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end

      context 'allow reporter to pull images' do
        before_all do
          project.add_reporter(current_user)
        end

        context 'when pulling from root level repository' do
          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:pull"] }
          end

          it_behaves_like 'a pullable'
          it_behaves_like 'not a container repository factory'
          it_behaves_like 'with auth_type'
        end
      end

      context 'disallow reporter to delete images' do
        before_all do
          project.add_reporter(current_user)
        end

        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:*"] }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end

      context 'disallow reporter to delete images since registry 2.7' do
        before_all do
          project.add_reporter(current_user)
        end

        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:delete"] }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end

      context 'return a least of privileges' do
        before_all do
          project.add_reporter(current_user)
        end

        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:push,pull"] }
        end

        it_behaves_like 'a pullable'
        it_behaves_like 'not a container repository factory'
        it_behaves_like 'with auth_type'
      end

      context 'disallow guest to pull or push images' do
        before_all do
          project.add_guest(current_user)
        end

        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:pull,push"] }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end

      context 'disallow guest to delete images' do
        before_all do
          project.add_guest(current_user)
        end

        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:*"] }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end

      context 'disallow guest to delete images since registry 2.7' do
        before_all do
          project.add_guest(current_user)
        end

        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:delete"] }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end
    end

    context 'for private project' do
      let_it_be_with_reload(:project) { create(:project) }

      it_behaves_like 'private project'
    end

    context 'for public project with private container registry' do
      let_it_be_with_reload(:project) { create(:project, :public, :container_registry_private) }

      it_behaves_like 'private project'
    end

    context 'for public project with container_registry `enabled`' do
      let_it_be(:project) { create(:project, :public, :container_registry_enabled) }

      context 'allow anyone to pull images' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:pull"] }
        end

        it_behaves_like 'a pullable'
        it_behaves_like 'not a container repository factory'
        it_behaves_like 'with auth_type'
      end

      context 'disallow anyone to push images' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:push"] }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end

      context 'disallow anyone to delete images' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:*"] }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end

      context 'disallow anyone to delete images since registry 2.7' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:delete"] }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end

      context 'when repository name is invalid' do
        let(:current_params) do
          { scopes: ['repository:invalid:push'] }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end
    end

    context 'for internal project with container_registry `enabled`' do
      let_it_be(:project) { create(:project, :internal, :container_registry_enabled) }

      context 'for internal user' do
        context 'allow anyone to pull images' do
          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:pull"] }
          end

          it_behaves_like 'a pullable'
          it_behaves_like 'not a container repository factory'
          it_behaves_like 'with auth_type'
        end

        context 'disallow anyone to push images' do
          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:push"] }
          end

          it_behaves_like 'an inaccessible'
          it_behaves_like 'not a container repository factory'
        end

        context 'disallow anyone to delete images' do
          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:*"] }
          end

          it_behaves_like 'an inaccessible'
          it_behaves_like 'not a container repository factory'
        end

        context 'disallow anyone to delete images since registry 2.7' do
          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:delete"] }
          end

          it_behaves_like 'an inaccessible'
          it_behaves_like 'not a container repository factory'
        end
      end

      context 'for external user' do
        context 'disallow anyone to pull or push images' do
          let_it_be(:current_user) { create(:user, external: true) }

          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:pull,push"] }
          end

          it_behaves_like 'an inaccessible'
          it_behaves_like 'not a container repository factory'
        end

        context 'disallow anyone to delete images' do
          let_it_be(:current_user) { create(:user, external: true) }

          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:*"] }
          end

          it_behaves_like 'an inaccessible'
          it_behaves_like 'not a container repository factory'
        end

        context 'disallow anyone to delete images since registry 2.7' do
          let_it_be(:current_user) { create(:user, external: true) }

          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:delete"] }
          end

          it_behaves_like 'an inaccessible'
          it_behaves_like 'not a container repository factory'
        end
      end
    end

    context 'for internal project with private container registry' do
      let_it_be_with_reload(:project) { create(:project, :internal, :container_registry_private) }

      it_behaves_like 'private project'
    end
  end

  context 'delete authorized as maintainer' do
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { create(:user) }

    before_all do
      project.add_maintainer(current_user)
    end

    it_behaves_like 'allowed to delete container repository images'
  end

  context 'build authorized as user' do
    let_it_be(:current_project) { create(:project) }
    let_it_be(:current_user) { create(:user) }

    let(:authentication_abilities) do
      [:build_read_container_image, :build_create_container_image, :build_destroy_container_image]
    end

    before_all do
      current_project.add_developer(current_user)
    end

    context 'allow to use offline_token' do
      let(:current_params) do
        { offline_token: true }
      end

      it_behaves_like 'an authenticated'
    end

    it_behaves_like 'a valid token'
    it_behaves_like 'with auth_type'

    context 'allow to pull and push images' do
      let(:current_params) do
        { scopes: ["repository:#{current_project.full_path}:pull,push"] }
      end

      it_behaves_like 'a pullable and pushable' do
        let(:project) { current_project }
      end

      it_behaves_like 'container repository factory' do
        let(:project) { current_project }
      end
    end

    context 'allow to delete images since registry 2.7' do
      let(:current_params) do
        { scopes: ["repository:#{current_project.full_path}:delete"] }
      end

      it_behaves_like 'a deletable since registry 2.7' do
        let(:project) { current_project }
      end
    end

    context 'disallow to delete images' do
      let(:current_params) do
        { scopes: ["repository:#{current_project.full_path}:*"] }
      end

      it_behaves_like 'an inaccessible' do
        let(:project) { current_project }
      end
    end

    context 'for other projects' do
      context 'when pulling' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:pull"] }
        end

        context 'allow for public' do
          let_it_be(:project) { create(:project, :public) }

          it_behaves_like 'a pullable'
          it_behaves_like 'not a container repository factory'
        end

        shared_examples 'pullable for being team member' do
          context 'when you are not member' do
            it_behaves_like 'an inaccessible'
            it_behaves_like 'not a container repository factory'
          end

          context 'when you are member' do
            before_all do
              project.add_developer(current_user)
            end

            it_behaves_like 'a pullable'
            it_behaves_like 'not a container repository factory'
          end

          context 'when you are owner' do
            let_it_be(:project) { create(:project, namespace: current_user.namespace) }

            it_behaves_like 'a pullable'
            it_behaves_like 'not a container repository factory'
          end
        end

        context 'for private' do
          let_it_be(:project) { create(:project, :private) }

          it_behaves_like 'pullable for being team member'

          context 'when you are admin' do
            let_it_be(:current_user) { create(:admin) }

            context 'when you are not member' do
              it_behaves_like 'an inaccessible'
              it_behaves_like 'not a container repository factory'
            end

            context 'when you are member' do
              before_all do
                project.add_developer(current_user)
              end

              it_behaves_like 'a pullable'
              it_behaves_like 'not a container repository factory'
            end

            context 'when you are owner' do
              let_it_be(:project) { create(:project, namespace: current_user.namespace) }

              it_behaves_like 'a pullable'
              it_behaves_like 'not a container repository factory'
            end
          end
        end

        context 'for public project with private container registry' do
          let_it_be_with_reload(:project) { create(:project, :public, :container_registry_private) }

          it_behaves_like 'pullable for being team member'

          context 'when you are admin' do
            let_it_be(:current_user) { create(:admin) }

            it_behaves_like 'pullable for being team member'
          end
        end
      end

      context 'when pushing' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:push"] }
        end

        context 'disallow for all' do
          context 'when you are member' do
            let_it_be(:project) { create(:project, :public) }

            before_all do
              project.add_developer(current_user)
            end

            it_behaves_like 'an inaccessible'
            it_behaves_like 'not a container repository factory'
          end

          context 'when you are owner' do
            let_it_be(:project) { create(:project, :public, namespace: current_user.namespace) }

            it_behaves_like 'an inaccessible'
            it_behaves_like 'not a container repository factory'
          end
        end
      end
    end

    context 'for project without container registry' do
      let_it_be_with_reload(:project) { create(:project, :public, :container_registry_disabled) }

      context 'disallow when pulling' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:pull"] }
        end

        it_behaves_like 'an inaccessible'
        it_behaves_like 'not a container repository factory'
      end
    end

    context 'for project that disables repository' do
      let_it_be(:project) { create(:project, :public, :repository_disabled) }

      context 'allow when pulling' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:pull"] }
        end

        it_behaves_like 'a pullable'
        it_behaves_like 'not a container repository factory'
      end
    end
  end

  context 'registry catalog browsing authorized as admin' do
    let_it_be(:current_user) { create(:user, :admin) }
    let_it_be(:project) { create(:project, :public) }

    let(:current_params) do
      { scopes: ["registry:catalog:*"] }
    end

    it_behaves_like 'a browsable'
  end

  context 'support for multiple scopes' do
    let_it_be(:internal_project) { create(:project, :internal) }
    let_it_be(:private_project) { create(:project, :private) }
    let_it_be(:public_project) { create(:project, :public) }
    let_it_be(:public_project_private_container_registry) { create(:project, :public, :container_registry_private) }

    let(:current_params) do
      {
        scopes: [
          "repository:#{internal_project.full_path}:pull",
          "repository:#{private_project.full_path}:pull",
          "repository:#{public_project.full_path}:pull",
          "repository:#{public_project_private_container_registry.full_path}:pull"
        ]
      }
    end

    context 'user has access to all projects' do
      let_it_be(:current_user) { create(:user, :admin) }

      before do
        enable_admin_mode!(current_user)
      end

      it_behaves_like 'a browsable' do
        let(:access) do
          [
            { 'type' => 'repository',
              'name' => internal_project.full_path,
              'actions' => ['pull'],
              'meta' => {
                'project_path' => internal_project.full_path,
                'project_id' => internal_project.id,
                'root_namespace_id' => internal_project.root_ancestor.id
              } },
            { 'type' => 'repository',
              'name' => private_project.full_path,
              'actions' => ['pull'],
              'meta' => {
                'project_path' => private_project.full_path,
                'project_id' => private_project.id,
                'root_namespace_id' => private_project.root_ancestor.id
              } },
            { 'type' => 'repository',
              'name' => public_project.full_path,
              'actions' => ['pull'],
              'meta' => {
                'project_path' => public_project.full_path,
                'project_id' => public_project.id,
                'root_namespace_id' => public_project.root_ancestor.id
              } },
            { 'type' => 'repository',
              'name' => public_project_private_container_registry.full_path,
              'actions' => ['pull'],
              'meta' => {
                'project_path' => public_project_private_container_registry.full_path,
                'project_id' => public_project_private_container_registry.id,
                'root_namespace_id' => public_project_private_container_registry.root_ancestor.id
              } }
          ]
        end
      end
    end

    context 'user only has access to internal and public projects' do
      let_it_be(:current_user) { create(:user) }

      it_behaves_like 'a browsable' do
        let(:access) do
          [
            { 'type' => 'repository',
              'name' => internal_project.full_path,
              'actions' => ['pull'],
              'meta' => {
                'project_path' => internal_project.full_path,
                'project_id' => internal_project.id,
                'root_namespace_id' => internal_project.root_ancestor.id
              } },
            { 'type' => 'repository',
              'name' => public_project.full_path,
              'actions' => ['pull'],
              'meta' => {
                'project_path' => public_project.full_path,
                'project_id' => public_project.id,
                'root_namespace_id' => public_project.root_ancestor.id
              } }
          ]
        end
      end
    end

    context 'anonymous user has access only to public project' do
      let(:current_user) { nil }

      it_behaves_like 'a browsable' do
        let(:access) do
          [
            { 'type' => 'repository',
              'name' => public_project.full_path,
              'actions' => ['pull'],
              'meta' => {
                'project_path' => public_project.full_path,
                'project_id' => public_project.id,
                'root_namespace_id' => public_project.root_ancestor.id
              } }
          ]
        end
      end

      context 'with no public container registry' do
        before do
          public_project.project_feature.update_column(:container_registry_access_level, ProjectFeature::PRIVATE)
        end

        it_behaves_like 'a forbidden'
      end
    end
  end

  context 'unauthorized' do
    context 'disallow to use scope-less authentication' do
      it_behaves_like 'a forbidden'
      it_behaves_like 'not a container repository factory'
    end

    context 'for invalid scope' do
      let(:current_params) do
        { scopes: ['invalid:aa:bb'] }
      end

      it_behaves_like 'a forbidden'
      it_behaves_like 'not a container repository factory'
    end

    context 'for private project' do
      let_it_be(:project) { create(:project, :private) }

      let(:current_params) do
        { scopes: ["repository:#{project.full_path}:pull"] }
      end

      it_behaves_like 'a forbidden'
    end

    context 'for public project with container registry `enabled`' do
      let_it_be_with_reload(:project) { create(:project, :public, :container_registry_enabled) }

      context 'when pulling and pushing' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:pull,push"] }
        end

        it_behaves_like 'a pullable'
        it_behaves_like 'not a container repository factory'
      end

      context 'when pushing' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:push"] }
        end

        it_behaves_like 'a forbidden'
        it_behaves_like 'not a container repository factory'
      end
    end

    context 'for public project with container registry `private`' do
      let_it_be_with_reload(:project) { create(:project, :public, :container_registry_private) }

      context 'when pulling and pushing' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:pull,push"] }
        end

        it_behaves_like 'a forbidden'
        it_behaves_like 'not a container repository factory'
      end
    end

    context 'for registry catalog' do
      let(:current_params) do
        { scopes: ["registry:catalog:*"] }
      end

      it_behaves_like 'a forbidden'
      it_behaves_like 'not a container repository factory'
    end
  end

  context 'for deploy tokens' do
    let(:current_params) do
      { scopes: ["repository:#{project.full_path}:pull"], deploy_token: deploy_token }
    end

    context 'when deploy token has read and write registry as scopes' do
      let(:deploy_token) { create(:deploy_token, write_registry: true, projects: [project]) }

      shared_examples 'able to login' do
        context 'registry provides read_container_image authentication_abilities' do
          let(:current_params) { { deploy_token: deploy_token, auth_type: :deploy_token } }
          let(:authentication_abilities) { [:read_container_image] }

          it_behaves_like 'an authenticated'

          it { expect(payload['auth_type']).to eq('deploy_token') }

          it "has encoded user information in the payload" do
            user_info = decode_user_info_from_payload(payload)

            expect(user_info["token_type"]).to eq('deploy_token')
            expect(user_info["username"]).to eq(deploy_token.username)
            expect(user_info["deploy_token_id"]).to eq(deploy_token.id)
          end
        end
      end

      context 'for public project' do
        let_it_be(:project) { create(:project, :public) }

        context 'when pulling' do
          it_behaves_like 'a pullable'
        end

        context 'when pushing' do
          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:push"], deploy_token: deploy_token }
          end

          it_behaves_like 'a pushable'
        end

        it_behaves_like 'able to login'
      end

      context 'for internal project' do
        let_it_be(:project) { create(:project, :internal) }

        context 'when pulling' do
          it_behaves_like 'a pullable'
        end

        context 'when pushing' do
          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:push"], deploy_token: deploy_token }
          end

          it_behaves_like 'a pushable'
        end

        it_behaves_like 'able to login'
      end

      context 'for private project' do
        let_it_be(:project) { create(:project, :private) }

        context 'when pulling' do
          it_behaves_like 'a pullable'
        end

        context 'when pushing' do
          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:push"], deploy_token: deploy_token }
          end

          it_behaves_like 'a pushable'
        end

        it_behaves_like 'able to login'
      end

      context 'for public project with private container registry' do
        let_it_be_with_reload(:project) { create(:project, :public, :container_registry_private) }

        context 'when pulling' do
          it_behaves_like 'a pullable'
        end

        context 'when pushing' do
          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:push"], deploy_token: deploy_token }
          end

          it_behaves_like 'a pushable'
        end

        it_behaves_like 'able to login'
      end
    end

    context 'when deploy token does not have read_registry scope' do
      let(:deploy_token) do
        create(:deploy_token, projects: [project], read_registry: false)
      end

      shared_examples 'unable to login' do
        context 'registry provides no container authentication_abilities' do
          let(:authentication_abilities) { [] }

          it_behaves_like 'a forbidden'
        end

        context 'registry provides inapplicable container authentication_abilities' do
          let(:authentication_abilities) { [:download_code] }

          it_behaves_like 'a forbidden'
        end
      end

      context 'for public project with container registry `enabled`' do
        let_it_be_with_reload(:project) { create(:project, :public, :container_registry_enabled) }

        context 'when pulling' do
          it_behaves_like 'a pullable'
        end

        it_behaves_like 'unable to login'
      end

      context 'for public project with container registry `private`' do
        let_it_be_with_reload(:project) { create(:project, :public, :container_registry_private) }

        context 'when pulling' do
          it_behaves_like 'an inaccessible'
        end

        it_behaves_like 'unable to login'
      end

      context 'for internal project' do
        let_it_be(:project) { create(:project, :internal) }

        context 'when pulling' do
          it_behaves_like 'an inaccessible'
        end

        it_behaves_like 'unable to login'
      end

      context 'for private project' do
        let_it_be(:project) { create(:project, :internal) }

        context 'when pulling' do
          it_behaves_like 'an inaccessible'
        end

        context 'when logging in' do
          let(:current_params) { {} }
          let(:authentication_abilities) { [] }

          it_behaves_like 'a forbidden'
        end

        it_behaves_like 'unable to login'
      end
    end

    context 'when deploy token is not related to the project' do
      let_it_be(:deploy_token) { create(:deploy_token, read_registry: false) }

      context 'for public project with container registry `enabled`' do
        let_it_be_with_reload(:project) { create(:project, :public, :container_registry_enabled) }

        context 'when pulling' do
          it_behaves_like 'a pullable'
        end
      end

      context 'for public project with container registry `private`' do
        let_it_be_with_reload(:project) { create(:project, :public, :container_registry_private) }

        context 'when pulling' do
          it_behaves_like 'an inaccessible'
        end
      end

      context 'for internal project' do
        let_it_be(:project) { create(:project, :internal) }

        context 'when pulling' do
          it_behaves_like 'an inaccessible'
        end
      end

      context 'for private project' do
        let_it_be(:project) { create(:project, :internal) }

        context 'when pulling' do
          it_behaves_like 'an inaccessible'
        end
      end
    end

    context 'when deploy token has been revoked' do
      let(:deploy_token) { create(:deploy_token, :revoked, projects: [project]) }

      context 'for public project with container registry `enabled`' do
        let_it_be(:project) { create(:project, :public, :container_registry_enabled) }

        it_behaves_like 'a pullable'
      end

      context 'for public project with container registry `private`' do
        let_it_be(:project) { create(:project, :public, :container_registry_private) }

        it_behaves_like 'an inaccessible'
      end

      context 'for internal project' do
        let_it_be(:project) { create(:project, :internal) }

        it_behaves_like 'an inaccessible'
      end

      context 'for private project' do
        let_it_be(:project) { create(:project, :internal) }

        it_behaves_like 'an inaccessible'
      end
    end
  end

  context 'user authorization' do
    let_it_be(:current_user) { create(:user) }

    context 'with multiple scopes' do
      let_it_be(:project) { create(:project) }

      context 'allow developer to push images' do
        before_all do
          project.add_developer(current_user)
        end

        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:push"] }
        end

        it_behaves_like 'a pushable'
        it_behaves_like 'container repository factory'
      end

      it "has encoded user information in the payload" do
        user_info = decode_user_info_from_payload(payload)

        expect(user_info["username"]).to eq(current_user.username)
        expect(user_info["user_id"]).to eq(current_user.id)
      end

      it_behaves_like 'with auth_type'
    end
  end

  context 'when importing' do
    let_it_be(:container_repository) { create(:container_repository, :root, :importing) }
    let_it_be(:current_project) { container_repository.project }
    let_it_be(:current_user) { create(:user) }

    before do
      current_project.add_developer(current_user)
    end

    shared_examples 'containing the import error' do
      it 'includes a helpful error message' do
        expect(subject[:errors].first).to include(message: /Your repository is currently being migrated/)
      end
    end

    context 'push request' do
      let(:current_params) do
        { scopes: ["repository:#{container_repository.path}:push"] }
      end

      it_behaves_like 'a forbidden' do
        it_behaves_like 'containing the import error'
      end
    end

    context 'delete request' do
      let(:current_params) do
        { scopes: ["repository:#{container_repository.path}:delete"] }
      end

      it_behaves_like 'a forbidden' do
        it_behaves_like 'containing the import error'
      end
    end

    context '* request' do
      let(:current_params) do
        { scopes: ["repository:#{container_repository.path}:*"] }
      end

      it_behaves_like 'a forbidden' do
        it_behaves_like 'containing the import error'
      end
    end

    context 'pull request' do
      let(:current_params) do
        { scopes: ["repository:#{container_repository.path}:pull"] }
      end

      let(:project) { current_project }

      it_behaves_like 'a pullable'
    end

    context 'mixed request' do
      let(:current_params) do
        { scopes: ["repository:#{container_repository.path}:pull,push"] }
      end

      let(:project) { current_project }

      it_behaves_like 'a forbidden' do
        it_behaves_like 'containing the import error'
      end
    end
  end

  context 'with a project with a path containing special characters' do
    let_it_be(:bad_project) { create(:project) }

    before do
      bad_project.update_attribute(:path, "#{bad_project.path}_")
    end

    describe '#access_token' do
      let(:token) { described_class.access_token({ bad_project.full_path => ['pull'] }) }
      let(:access) do
        { 'type' => 'repository',
          'name' => bad_project.full_path,
          'actions' => ['pull'] }
      end

      subject { { token: token } }

      it_behaves_like 'a valid token'

      it 'has the correct scope' do
        expect(payload).to include('access' => [access])
      end

      context 'with an override project path' do
        let(:override_project_path) { 'group/project-override' }
        let(:token) do
          described_class.access_token(
            { bad_project.full_path => ['pull'] },
            override_project_path: override_project_path
          )
        end

        it 'returns the override project path in the metadata' do
          expect(payload).to include('access' => [
            access.merge("meta" => { "project_path" => override_project_path })
          ])
        end
      end
    end
  end

  context 'with container registry protection rules' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:current_project) { create(:project) }
    let_it_be(:project) { current_project }
    let_it_be(:current_user) { create(:user) }

    let_it_be(:container_repository_path) { current_project.full_path }
    let_it_be(:container_repository_path_pattern_no_match) { "#{container_repository_path}_no_match" }

    let_it_be_with_reload(:container_registry_protection_rule) do
      create(:container_registry_protection_rule, project: current_project,
        repository_path_pattern: container_repository_path)
    end

    let_it_be(:project_developer) { create(:user, developer_of: current_project) }
    let_it_be(:project_maintainer) { create(:user, maintainer_of: current_project) }
    let_it_be(:project_owner) { current_project.owner }

    let(:current_params) { { scopes: ["repository:#{container_repository_path}:push"] } }

    shared_examples 'a protected container repository' do
      it_behaves_like 'a forbidden'

      it do
        is_expected.to include errors: [include(code: "DENIED",
          message: 'Pushing to protected repository path forbidden')]
      end
    end

    context 'for different repository_path_patterns and current user roles' do
      # rubocop:disable Layout/LineLength -- Avoid formatting to keep one-line table layout
      where(:repository_path_pattern, :push_protected_up_to_access_level, :current_user, :shared_examples_name) do
        ref(:container_repository_path)                  | :developer  | ref(:project_developer)  | 'a protected container repository'
        ref(:container_repository_path)                  | :developer  | ref(:project_owner)      | 'a pushable'
        ref(:container_repository_path)                  | :maintainer | ref(:project_maintainer) | 'a protected container repository'
        ref(:container_repository_path)                  | :owner      | ref(:project_owner)      | 'a protected container repository'
        ref(:container_repository_path_pattern_no_match) | :developer  | ref(:project_developer)  | 'a pushable'
        ref(:container_repository_path_pattern_no_match) | :owner      | ref(:project_owner)      | 'a pushable'
      end
      # rubocop:enable Layout/LineLength

      with_them do
        before do
          container_registry_protection_rule.update!(
            repository_path_pattern: repository_path_pattern,
            push_protected_up_to_access_level: push_protected_up_to_access_level
          )
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'with different scopes and actions' do
      let_it_be(:current_user) { project_maintainer }

      before do
        container_registry_protection_rule.update!(push_protected_up_to_access_level: :maintainer)
      end

      where(:current_params_scopes, :shared_examples_name) do
        lazy { ["repository:#{container_repository_path}:*"] }         | 'a protected container repository'
        lazy { ["repository:#{container_repository_path}:push"] }      | 'a protected container repository'
        lazy { ["repository:#{container_repository_path}:push,pull"] } | 'a protected container repository'
        lazy { ["repository:#{container_repository_path}:pull"] }      | 'a pullable'
      end

      with_them do
        let(:current_params) { { scopes: current_params_scopes } }

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'when feature flag :container_registry_protected_containers is disabled' do
      let_it_be(:current_user) { current_project.owner }

      before do
        stub_feature_flags(container_registry_protected_containers: false)
      end

      context 'with matching package protection rule for all roles' do
        where(:repository_path_pattern, :push_protected_up_to_access_level, :shared_examples_name) do
          ref(:container_repository_path)                  | :developer | 'a pushable'
          ref(:container_repository_path)                  | :owner     | 'a pushable'
          ref(:container_repository_path_pattern_no_match) | :developer | 'a pushable'
          ref(:container_repository_path_pattern_no_match) | :owner     | 'a pushable'
        end

        with_them do
          before do
            container_registry_protection_rule.update!(
              repository_path_pattern: repository_path_pattern,
              push_protected_up_to_access_level: push_protected_up_to_access_level
            )
          end

          it_behaves_like params[:shared_examples_name]
        end
      end
    end
  end

  def decode_user_info_from_payload(payload)
    JWT.decode(payload["user"], nil, false)[0]["user_info"]
  end
end
