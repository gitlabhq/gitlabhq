# frozen_string_literal: true

RSpec.shared_context 'container registry auth service context' do
  let(:current_project) { nil }
  let(:current_user) { nil }
  let(:current_params) { {} }
  let(:rsa_key) { OpenSSL::PKey::RSA.generate(512) }
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
       'actions' => actions }]
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
    let(:actions) { %w(pull push) }
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
      user_id: current_user.id,
      username: current_user.username
    }
  end

  it do
    expect(Gitlab::AuthLogger).to receive(:warn).with(expected.merge!(log_data))

    subject
  end
end

RSpec.shared_examples 'a container registry auth service' do
  include_context 'container registry auth service context'

  before do
    stub_feature_flags(container_registry_migration_phase1: false)
  end

  describe '#full_access_token' do
    let_it_be(:project) { create(:project) }

    let(:token) { described_class.full_access_token(project.full_path) }

    subject { { token: token } }

    it_behaves_like 'an accessible' do
      let(:actions) { ['*'] }
    end

    it_behaves_like 'not a container repository factory'
  end

  describe '#pull_access_token' do
    let_it_be(:project) { create(:project) }

    let(:token) { described_class.pull_access_token(project.full_path) }

    subject { { token: token } }

    it_behaves_like 'an accessible' do
      let(:actions) { ['pull'] }
    end

    it_behaves_like 'not a container repository factory'
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

    context 'for private project' do
      let_it_be(:project) { create(:project) }

      context 'allow to use scope-less authentication' do
        it_behaves_like 'a valid token'
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

    context 'for public project' do
      let_it_be(:project) { create(:project, :public) }

      context 'allow anyone to pull images' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:pull"] }
        end

        it_behaves_like 'a pullable'
        it_behaves_like 'not a container repository factory'
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

    context 'for internal project' do
      let_it_be(:project) { create(:project, :internal) }

      context 'for internal user' do
        context 'allow anyone to pull images' do
          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:pull"] }
          end

          it_behaves_like 'a pullable'
          it_behaves_like 'not a container repository factory'
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
  end

  context 'delete authorized as maintainer' do
    let_it_be(:current_project) { create(:project) }
    let_it_be(:current_user) { create(:user) }

    let(:authentication_abilities) do
      [:admin_container_image]
    end

    before_all do
      current_project.add_maintainer(current_user)
    end

    it_behaves_like 'a valid token'

    context 'allow to delete images' do
      let(:current_params) do
        { scopes: ["repository:#{current_project.full_path}:*"] }
      end

      it_behaves_like 'a deletable' do
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
      let_it_be(:project) { create(:project, :public, container_registry_enabled: false) }

      before do
        project.update!(container_registry_enabled: false)
      end

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

      context 'disallow when pulling' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:pull"] }
        end

        it_behaves_like 'an inaccessible'
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

    let(:current_params) do
      {
        scopes: [
          "repository:#{internal_project.full_path}:pull",
          "repository:#{private_project.full_path}:pull"
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
              'actions' => ['pull'] },
            { 'type' => 'repository',
              'name' => private_project.full_path,
              'actions' => ['pull'] }
          ]
        end
      end
    end

    context 'user only has access to internal project' do
      let_it_be(:current_user) { create(:user) }

      it_behaves_like 'a browsable' do
        let(:access) do
          [
            { 'type' => 'repository',
              'name' => internal_project.full_path,
              'actions' => ['pull'] }
          ]
        end
      end
    end

    context 'anonymous access is rejected' do
      let(:current_user) { nil }

      it_behaves_like 'a forbidden'
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

    context 'for public project' do
      let_it_be(:project) { create(:project, :public) }

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
      { scopes: ["repository:#{project.full_path}:pull"] }
    end

    context 'when deploy token has read and write registry as scopes' do
      let(:current_user) { create(:deploy_token, write_registry: true, projects: [project]) }

      shared_examples 'able to login' do
        context 'registry provides read_container_image authentication_abilities' do
          let(:current_params) { {} }
          let(:authentication_abilities) { [:read_container_image] }

          it_behaves_like 'an authenticated'
        end
      end

      context 'for public project' do
        let_it_be(:project) { create(:project, :public) }

        context 'when pulling' do
          it_behaves_like 'a pullable'
        end

        context 'when pushing' do
          let(:current_params) do
            { scopes: ["repository:#{project.full_path}:push"] }
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
            { scopes: ["repository:#{project.full_path}:push"] }
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
            { scopes: ["repository:#{project.full_path}:push"] }
          end

          it_behaves_like 'a pushable'
        end

        it_behaves_like 'able to login'
      end
    end

    context 'when deploy token does not have read_registry scope' do
      let(:current_user) { create(:deploy_token, projects: [project], read_registry: false) }

      shared_examples 'unable to login' do
        context 'registry provides no container authentication_abilities' do
          let(:current_params) { {} }
          let(:authentication_abilities) { [] }

          it_behaves_like 'a forbidden'
        end

        context 'registry provides inapplicable container authentication_abilities' do
          let(:current_params) { {} }
          let(:authentication_abilities) { [:download_code] }

          it_behaves_like 'a forbidden'
        end
      end

      context 'for public project' do
        let_it_be(:project) { create(:project, :public) }

        context 'when pulling' do
          it_behaves_like 'a pullable'
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
      let_it_be(:current_user) { create(:deploy_token, read_registry: false) }

      context 'for public project' do
        let_it_be(:project) { create(:project, :public) }

        context 'when pulling' do
          it_behaves_like 'a pullable'
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
      let(:current_user) { create(:deploy_token, :revoked, projects: [project]) }

      context 'for public project' do
        let_it_be(:project) { create(:project, :public) }

        it_behaves_like 'a pullable'
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
    end
  end
end
