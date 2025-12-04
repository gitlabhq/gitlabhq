# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::TrackComponentUsageWorker, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:resource) { create(:ci_catalog_resource) }

  let_it_be(:release) { create(:release, project: resource.project, tag: '1.2.0', sha: 'my_component_sha') }
  let_it_be(:version) do
    create(:ci_catalog_resource_version, catalog_resource: resource, release: release, semver: release.tag)
  end

  let_it_be(:component) { create(:ci_catalog_resource_component, version: version, name: 'my_component') }

  let(:component_hash) do
    {
      'project_id' => component.project.id,
      'sha' => version.sha,
      'name' => component.name
    }
  end

  describe '#perform' do
    subject(:perform) { described_class.new.perform(project.id, user.id, [component_hash]) }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [project.id, user.id, [component_hash]] }

      it 'tracks the component usage event' do
        expect { perform }.to trigger_internal_events('ci_catalog_component_included')
      end

      it 'creates a component usage record' do
        expect { perform }.to change { Ci::Catalog::Resources::Components::LastUsage.count }.by(1)
      end
    end

    context 'when project does not exist' do
      it 'does not track usage' do
        expect do
          described_class.new.perform(non_existing_record_id, user.id, [component_hash])
        end.not_to change { Ci::Catalog::Resources::Components::LastUsage.count }
      end
    end

    context 'when user does not exist' do
      it 'does not track usage' do
        expect do
          described_class.new.perform(project.id, non_existing_record_id, [component_hash])
        end.not_to change { Ci::Catalog::Resources::Components::LastUsage.count }
      end
    end

    context 'when component project does not exist' do
      it 'does not track usage' do
        expect do
          described_class.new.perform(
            project.id, user.id,
            [{ 'project_id' => non_existing_record_id, 'sha' => version.sha,
               'name' => component.name }])
        end.not_to change { Ci::Catalog::Resources::Components::LastUsage.count }
      end
    end

    context 'when component does not exist' do
      let(:invalid_component_hash) do
        {
          'project_id' => component.project.id,
          'sha' => version.sha,
          'name' => 'nonexistent_component'
        }
      end

      it 'does not track usage' do
        expect do
          described_class.new.perform(project.id, user.id, [invalid_component_hash])
        end.not_to change { Ci::Catalog::Resources::Components::LastUsage.count }
      end
    end

    context 'when processing multiple components' do
      let_it_be(:component2) { create(:ci_catalog_resource_component, version: version, name: 'another_component') }

      let(:component_hash2) do
        {
          'project_id' => component2.project.id,
          'sha' => version.sha,
          'name' => component2.name
        }
      end

      it 'tracks all components' do
        expect do
          described_class.new.perform(project.id, user.id, [component_hash, component_hash2])
        end.to change { Ci::Catalog::Resources::Components::LastUsage.count }.by(2)
      end
    end

    context 'when component usage has already been recorded', :freeze_time do
      let!(:existing_last_usage) do
        create(:catalog_resource_component_last_usage,
          component: component, used_by_project_id: project.id, last_used_date: Time.current.to_date - 3.days)
      end

      it 'updates the last_used_date for the existing last_usage record' do
        expect { perform }.not_to change { Ci::Catalog::Resources::Components::LastUsage.count }

        last_usage = Ci::Catalog::Resources::Components::LastUsage.find_by(component: component,
          used_by_project_id: project.id)
        expect(last_usage.last_used_date).to eq(Time.current.to_date)
      end
    end

    context 'when tracking fails' do
      before do
        allow(Gitlab::InternalEvents).to receive(:track_event).and_raise(StandardError.new('tracking error'))
      end

      it 'tracks the exception to Sentry' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(StandardError))

        perform
      end
    end

    context 'when one component fails but others succeed' do
      let_it_be(:component2) { create(:ci_catalog_resource_component, version: version, name: 'another_component') }

      let(:component_hash2) do
        {
          'project_id' => component2.project.id,
          'sha' => version.sha,
          'name' => component2.name
        }
      end

      before do
        allow(Gitlab::InternalEvents).to receive(:track_event).and_call_original
        allow(Gitlab::InternalEvents).to receive(:track_event)
          .with('ci_catalog_component_included',
            hash_including(additional_properties: hash_including(label: /my_component/)))
          .and_raise(StandardError.new('tracking error'))
      end

      it 'tracks the error and continues processing other components' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).once

        expect do
          described_class.new.perform(project.id, user.id, [component_hash, component_hash2])
        end.to change { Ci::Catalog::Resources::Components::LastUsage.count }.by(1)
      end
    end
  end
end
