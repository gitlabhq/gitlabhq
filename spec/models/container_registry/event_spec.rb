# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Event do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group, name: 'group') }
  let_it_be(:project) { create(:project, name: 'test', namespace: group) }

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
          'repository' =>  repository_path,
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
  end
end
