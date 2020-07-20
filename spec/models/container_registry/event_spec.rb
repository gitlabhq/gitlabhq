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
    let(:raw_event) { { 'action' => 'push', 'target' => { 'mediaType' => ContainerRegistry::Client::DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE } } }

    subject { described_class.new(raw_event).handle! }

    it { is_expected.to eq nil }
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
