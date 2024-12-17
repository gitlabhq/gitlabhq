# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Event, feature_category: :container_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group, name: 'group') }
  let_it_be(:project) { create(:project, path: 'test', namespace: group) }

  describe '#supported?' do
    let(:raw_event) { { 'action' => action } }

    subject { described_class.new(raw_event).supported? }

    where(:action, :supported) do
      'delete' | true
      'push'   | true
      'mount'  | false
      'pull'   | false
    end

    with_them do
      it { is_expected.to eq supported }
    end
  end

  describe '#handle!' do
    let(:action) { 'push' }
    let(:repository) { project.full_path }
    let(:target) do
      {
        'mediaType' => ContainerRegistry::Client::DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE,
        'tag' => 'latest',
        'repository' => repository
      }
    end

    let(:raw_event) { { 'action' => action, 'target' => target } }

    subject(:handle!) { described_class.new(raw_event).handle! }

    shared_examples 'event with project statistics update' do
      it 'enqueues a project statistics update' do
        expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], %w[container_registry_size])

        handle!
      end

      it 'clears the cache for the namespace container repositories size' do
        expect(Rails.cache).to receive(:delete).with(group.container_repositories_size_cache_key)

        handle!
      end
    end

    shared_examples 'event without project statistics update' do
      it 'does not queue a project statistics update' do
        expect(ProjectCacheWorker).not_to receive(:perform_async)

        handle!
      end
    end

    it_behaves_like 'event with project statistics update'

    context 'with no target tag' do
      let(:target) { super().without('tag') }

      it_behaves_like 'event without project statistics update'

      context 'with a target digest' do
        let(:target) { super().merge('digest' => 'abc123') }

        it_behaves_like 'event without project statistics update'
      end

      context 'with a delete action' do
        let(:action) { 'delete' }

        context 'without a target digest' do
          it_behaves_like 'event without project statistics update'
        end

        context 'with a target digest' do
          let(:target) { super().merge('digest' => 'abc123') }

          it_behaves_like 'event with project statistics update'
        end
      end
    end

    context 'with an unsupported action' do
      let(:action) { 'pull' }

      it_behaves_like 'event without project statistics update'
    end

    context 'with an invalid project repository path' do
      let(:repository) { 'does/not/exist' }

      it_behaves_like 'event without project statistics update'
    end

    context 'with no project repository path' do
      let(:repository) { nil }

      it_behaves_like 'event without project statistics update'
    end
  end

  describe '#track!' do
    let_it_be(:container_repository) { create(:container_repository, name: 'container', project: project) }

    let_it_be(:rsa_key) { OpenSSL::PKey::RSA.generate(3072) }
    let(:raw_event) { { 'action' => action, 'target' => target } }
    let(:key_file) { Tempfile.new('keypath') }

    before do
      allow(Gitlab.config.registry).to receive_messages(enabled: true, issuer: 'rspec', key: key_file.path)
      allow(OpenSSL::PKey::RSA).to receive(:new).and_return(rsa_key)

      allow_next_instance_of(JSONWebToken::RSAToken) do |instance|
        allow(instance).to receive(:key).and_return(rsa_key)
      end
    end

    subject { described_class.new(raw_event).track! }

    shared_examples 'tracking event is sent to HLLRedisCounter with event and originator ID' do |originator_type|
      it 'sends a tracking event to HLLRedisCounter' do
        expect(::Gitlab::UsageDataCounters::HLLRedisCounter)
        .to receive(:track_event).with("i_container_registry_#{event}_#{originator_type}", values: originator.id)
        .exactly(count).time

        subject
      end
    end

    shared_examples 'event originator is fetched based on ID' do |originator_class|
      it 'fetches the event originator based on id' do
        count.times do
          expect(originator_class).to receive(:find).with(originator.id)
        end

        subject
      end
    end

    context 'with a respository target' do
      let(:target) do
        {
          'mediaType' => ContainerRegistry::Client::DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE,
          'repository' => repository_path
        }
      end

      where(:repository_path, :action, :tracking_action) do
        'group/test/container' | 'push'   | 'push_repository'
        'group/test/container' | 'delete' | 'delete_repository'
        'foo/bar'              | 'push'   | 'create_repository'
        'foo/bar'              | 'delete' | 'delete_repository'
      end

      with_them do
        it 'creates a tracking event' do
          expect(::Gitlab::Tracking).to receive(:event).with('container_registry:notification', tracking_action)

          subject
        end
      end
    end

    context 'with a tag target' do
      let(:target) do
        {
          'mediaType' => ContainerRegistry::Client::DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE,
          'repository' => repository_path,
          'tag' => 'latest'
        }
      end

      where(:repository_path, :action, :tracking_action) do
        'group/test/container' | 'push'   | 'push_tag'
        'group/test/container' | 'delete' | 'delete_tag'
        'foo/bar'              | 'push'   | 'push_tag'
        'foo/bar'              | 'delete' | 'delete_tag'
      end

      with_them do
        it 'creates a tracking event' do
          expect(::Gitlab::Tracking).to receive(:event).with('container_registry:notification', tracking_action)

          subject
        end
      end
    end

    context 'with a deploy token as the actor' do
      let!(:originator) { create(:deploy_token, username: 'username', id: 3) }

      shared_examples 'no tracking of a deploy token is sent to HLLRedisCounter' do
        it 'does not send a tracking event to HLLRedisCounter' do
          expect(DeployToken).not_to receive(:find)
          expect(DeployToken).not_to receive(:find_by_username)
          expect(::Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

          expect { subject }.not_to raise_error
        end
      end

      context 'when only username is provided and no deploy_token_id is given' do
        let(:raw_event) do
          {
            'action' => 'push',
            'target' => { 'tag' => 'latest' },
            'actor' => { 'user_type' => 'deploy_token', 'name' => originator.username }
          }
        end

        it_behaves_like 'no tracking of a deploy token is sent to HLLRedisCounter'
      end

      context 'when no username or deploy_token_id is given' do
        let(:raw_event) { { 'action' => 'push', 'target' => {}, 'actor' => { 'user_type' => 'deploy_token' } } }

        it_behaves_like 'no tracking of a deploy token is sent to HLLRedisCounter'
      end

      context 'when deploy_token_id is given' do
        let(:deploy_token_info) do
          {
            token_type: 'deploy_token',
            username: originator.username,
            deploy_token_id: originator.id
          }
        end

        let(:token) do
          JSONWebToken::RSAToken.new(rsa_key).tap do |token|
            token[:user_info] = deploy_token_info
          end
        end

        let(:raw_event) do
          {
            'action' => action,
            'target' => target,
            'actor' => { 'user_type' => 'deploy_token', 'name' => originator.username, 'user' => token.encoded }
          }
        end

        where(:target, :action, :event, :count) do
          { 'tag' => 'latest' }          | 'push'     | 'push_tag'           |  1
          { 'tag' => 'latest' }          | 'delete'   | 'delete_tag'         |  1
          { 'repository' => 'foo/bar' }  | 'push'     | 'create_repository'  |  1
          { 'repository' => 'foo/bar' }  | 'delete'   | 'delete_repository'  |  1
          { 'tag' => 'latest' }          | 'copy'     | ''                   |  0
        end

        with_them do
          it_behaves_like 'event originator is fetched based on ID', DeployToken
          it_behaves_like 'tracking event is sent to HLLRedisCounter with event and originator ID', :deploy_token
        end

        context "when there are errors" do
          let(:action) { 'push' }
          let(:target) { { 'tag' => 'latest' } }

          context 'when the registry key file does not exist' do
            before do
              allow(File).to receive(:read).and_call_original
              allow(File).to receive(:read).with(key_file.path).and_raise(Errno::ENOENT)
            end

            it_behaves_like 'no tracking of a deploy token is sent to HLLRedisCounter'
          end

          [JWT::VerificationError, JWT::DecodeError, JWT::ExpiredSignature, JWT::ImmatureSignature].each do |error|
            context "when JWT decoding encounters #{error}" do
              before do
                allow(JWT).to receive(:decode)
                .with(token.encoded, rsa_key, true, { algorithm: "RS256" })
                .and_raise(error)
              end

              it_behaves_like 'no tracking of a deploy token is sent to HLLRedisCounter'
            end
          end
        end
      end
    end

    context 'with a user as the actor' do
      let_it_be(:originator) { create(:user, username: 'username') }

      context 'when user_id is available' do
        let(:user_info) do
          {
            token_type: user_type,
            username: originator.username,
            user_id: originator.id
          }
        end

        let(:token) do
          JSONWebToken::RSAToken.new(rsa_key).tap do |token|
            token[:user_info] = user_info
          end
        end

        let(:raw_event) do
          {
            'action' => action,
            'target' => target,
            'actor' => { 'user_type' => user_type, 'name' => originator.username, 'user' => token.encoded }
          }
        end

        where(:target, :action, :event, :user_type, :count) do
          { 'tag' => 'latest' }          | 'push'     | 'push_tag'           |  'personal_access_token'   |  1
          { 'tag' => 'latest' }          | 'delete'   | 'delete_tag'         |  'personal_access_token'   |  1
          { 'repository' => 'foo/bar' }  | 'push'     | 'create_repository'  |  'build'                   |  1
          { 'repository' => 'foo/bar' }  | 'delete'   | 'delete_repository'  |  'gitlab_or_ldap'          |  1
          { 'repository' => 'foo/bar' }  | 'delete'   | 'delete_repository'  |  'not_a_user'              |  0
          { 'tag' => 'latest' }          | 'copy'     | ''                   |  nil                       |  0
          { 'repository' => 'foo/bar' }  | 'copy'     | ''                   |  ''                        |  0
        end

        with_them do
          it_behaves_like 'event originator is fetched based on ID', User
          it_behaves_like 'tracking event is sent to HLLRedisCounter with event and originator ID', :user
        end
      end

      context 'when only username is available and user_id is not' do
        let(:raw_event) do
          {
            'action' => 'push',
            'target' => { 'tag' => 'latest' },
            'actor' => { 'user_type' => 'personal_access_token', 'name' => originator.username }
          }
        end

        it 'does not send a tracking event to HLLRedisCounter' do
          expect(::Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

          subject
        end
      end

      context 'when no username or id is given' do
        let(:raw_event) { { 'action' => 'push', 'target' => {}, 'actor' => { 'user_type' => 'build' } } }

        it 'does not send a tracking event to HLLRedisCounter' do
          expect(::Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

          subject
        end
      end
    end

    context 'when it is a manifest delete event' do
      let(:raw_event) { { 'action' => 'delete', 'target' => { 'digest' => 'x' }, 'actor' => {} } }

      it 'calls the ContainerRegistryEventCounter' do
        expect(::Gitlab::UsageDataCounters::ContainerRegistryEventCounter)
          .to receive(:count).with('i_container_registry_delete_manifest')

        subject
      end
    end

    context 'when it is not a manifest delete event' do
      let(:raw_event) { { 'action' => 'push', 'target' => { 'digest' => 'x' }, 'actor' => {} } }

      it 'does not call the ContainerRegistryEventCounter' do
        expect(::Gitlab::UsageDataCounters::ContainerRegistryEventCounter)
          .not_to receive(:count).with('i_container_registry_delete_manifest')

        subject
      end
    end
  end
end
