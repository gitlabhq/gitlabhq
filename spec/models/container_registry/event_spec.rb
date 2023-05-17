# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Event do
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
        expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], [:container_registry_size])

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

    let(:raw_event) { { 'action' => action, 'target' => target } }

    subject { described_class.new(raw_event).track! }

    shared_examples 'tracking event is sent to HLLRedisCounter with event and originator ID' do |originator_type|
      it 'fetches the event originator based on username' do
        count.times do
          expect(User).to receive(:find_by_username).with(originator.username)
        end

        subject
      end

      it 'sends a tracking event to HLLRedisCounter' do
        expect(::Gitlab::UsageDataCounters::HLLRedisCounter)
        .to receive(:track_event).with("i_container_registry_#{event}_#{originator_type}", values: originator.id)
        .exactly(count).time

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
      let(:raw_event) do
        {
          'action' => 'push',
          'target' => { 'tag' => 'latest' },
          'actor' => { 'user_type' => 'deploy_token', 'name' => originator.username }
        }
      end

      it 'does not send a tracking event to HLLRedisCounter' do
        expect(::Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        subject
      end
    end

    context 'with a user as the actor' do
      let_it_be(:originator) { create(:user, username: 'username') }
      let(:raw_event) do
        {
          'action' => action,
          'target' => target,
          'actor' => { 'user_type' => user_type, 'name' => originator.username }
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
        it_behaves_like 'tracking event is sent to HLLRedisCounter with event and originator ID', :user
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

    context 'without an actor name' do
      let(:raw_event) { { 'action' => 'push', 'target' => {}, 'actor' => { 'user_type' => 'personal_access_token' } } }

      it 'does not send a tracking event to HLLRedisCounter' do
        expect(User).not_to receive(:find_by_username)
        expect(::Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        subject
      end
    end
  end
end
