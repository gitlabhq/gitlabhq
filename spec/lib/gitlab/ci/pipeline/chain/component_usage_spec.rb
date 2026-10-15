# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::ComponentUsage, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be_with_reload(:resource) { create(:ci_catalog_resource) }

  let_it_be_with_reload(:release) do
    create(:release, project: resource.project, tag: '1.2.0', sha: 'my_component_sha')
  end

  let_it_be(:version) do
    create(:ci_catalog_resource_version, catalog_resource: resource, release: release, semver: release.tag)
  end

  let_it_be(:component) { create(:ci_catalog_resource_component, version: version, name: 'my_component') }

  let(:dry_run) { false }
  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user, dry_run: dry_run,
      origin_ref: 'refs/heads/main')
  end

  let(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    subject(:perform) { step.perform! }

    let(:component_hash) do
      {
        project: component.project,
        sha: version.sha,
        name: component.name
      }
    end

    before do
      allow(command).to receive(:yaml_processor_result)
        .and_return(instance_double(Gitlab::Ci::YamlProcessor::Result,
          included_components: [component_hash]
        ))
    end

    it 'enqueues the TrackComponentUsageWorker with all components' do
      serialized_components = [{
        'project_id' => component.project.id,
        'sha' => version.sha,
        'name' => component.name
      }]

      expect(::Ci::Catalog::Resources::TrackComponentUsageWorker).to receive(:perform_async)
        .with(project.id, user.id, serialized_components)

      perform
    end

    it 'does not create component usage records synchronously' do
      expect { perform }.not_to change { Ci::Catalog::Resources::Components::LastUsage.count }
    end

    context 'when there are multiple components' do
      let(:component_hash2) do
        {
          project: component.project,
          sha: version.sha,
          name: 'another_component'
        }
      end

      before do
        allow(command).to receive(:yaml_processor_result)
          .and_return(instance_double(Gitlab::Ci::YamlProcessor::Result,
            included_components: [component_hash, component_hash2]
          ))
      end

      it 'enqueues one worker with all components' do
        serialized_components = [
          {
            'project_id' => component.project.id,
            'sha' => version.sha,
            'name' => component.name
          },
          {
            'project_id' => component.project.id,
            'sha' => version.sha,
            'name' => 'another_component'
          }
        ]

        expect(::Ci::Catalog::Resources::TrackComponentUsageWorker).to receive(:perform_async)
          .once
          .with(project.id, user.id, serialized_components)

        perform
      end
    end

    context 'when a component resolved from a bundle' do
      let(:bundled_component_hash) { { project: nil, sha: 'bundle_sha', name: 'bundled_component' } }

      before do
        allow(command).to receive(:yaml_processor_result)
          .and_return(instance_double(Gitlab::Ci::YamlProcessor::Result,
            included_components: included_components
          ))
      end

      context 'with source components too' do
        let(:included_components) { [component_hash, bundled_component_hash] }

        it 'tracks only the source components' do
          expect(::Ci::Catalog::Resources::TrackComponentUsageWorker).to receive(:perform_async)
            .with(project.id, user.id, [{
              'project_id' => component.project.id,
              'sha' => version.sha,
              'name' => component.name
            }])

          perform
        end
      end

      context 'with only bundled components' do
        let(:included_components) { [bundled_component_hash] }

        it 'does not enqueue the worker' do
          expect(::Ci::Catalog::Resources::TrackComponentUsageWorker).not_to receive(:perform_async)
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          perform
        end
      end
    end

    context 'when current_user is nil' do
      let(:command) do
        Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: nil, dry_run: dry_run,
          origin_ref: 'refs/heads/main')
      end

      it 'enqueues the worker with nil user_id' do
        serialized_components = [{
          'project_id' => component.project.id,
          'sha' => version.sha,
          'name' => component.name
        }]

        expect(::Ci::Catalog::Resources::TrackComponentUsageWorker).to receive(:perform_async)
          .with(project.id, nil, serialized_components)

        perform
      end
    end

    context 'when enqueuing a worker fails' do
      before do
        allow(::Ci::Catalog::Resources::TrackComponentUsageWorker).to receive(:perform_async)
          .and_raise(StandardError.new('Redis error'))
      end

      it 'tracks the exception to Sentry and continues' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          instance_of(StandardError),
          project_id: project.id
        )

        expect { perform }.not_to raise_error
      end
    end
  end
end
