# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WorkItems::Instrumentation::TrackingService, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, developers: user) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  let(:other_user) { create(:user) }

  let(:service) { described_class.new(**service_params) }
  let(:service_params) { base_params.merge(additional_params) }
  let(:base_params) { { work_item: work_item, current_user: user } }
  let(:additional_params) { {} }

  let!(:expected_properties) do
    {
      user: user,
      project: project,
      namespace: project.project_namespace,
      additional_properties: {
        label: work_item.work_item_type.name,
        property: "Developer"
      }
    }
  end

  describe '#initialize' do
    context 'with valid parameters' do
      it 'initializes successfully with an event' do
        expect do
          described_class.new(
            work_item: work_item,
            current_user: user,
            event: Gitlab::WorkItems::Instrumentation::EventActions::NOTE_CREATE
          )
        end.not_to raise_error
      end

      it 'initializes successfully with nil event' do
        expect do
          described_class.new(
            work_item: work_item,
            current_user: user,
            event: nil,
            old_associations: {}
          )
        end.not_to raise_error
      end
    end

    context 'with invalid parameters' do
      it 'raises ArgumentError when work_item is not an Issue' do
        expect do
          described_class.new(
            work_item: 'not an issue',
            current_user: user,
            event: nil
          )
        end.to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when current_user is not a User' do
        expect do
          described_class.new(
            work_item: work_item,
            current_user: 'not a user',
            event: nil
          )
        end.to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when event is invalid' do
        expect do
          described_class.new(
            work_item: work_item,
            current_user: user,
            event: 'invalid_event'
          )
        end.to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when both event and old_associations are provided' do
        expect do
          described_class.new(
            work_item: work_item,
            current_user: user,
            event: Gitlab::WorkItems::Instrumentation::EventActions::NOTE_CREATE,
            old_associations: { status: 'open' }
          )
        end.to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when neither event nor old_associations are provided' do
        expect do
          described_class.new(
            work_item: work_item,
            current_user: user,
            event: nil,
            old_associations: nil
          )
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe '#execute', :clean_gitlab_redis_shared_state do
    context 'when event is provided directly' do
      let(:additional_params) { { event: ::Gitlab::WorkItems::Instrumentation::EventActions::NOTE_DESTROY } }

      it 'triggers the single event' do
        expect { service.execute }
          .to trigger_internal_events('work_item_note_destroy')
          .with(expected_properties)
      end
    end

    context 'when detecting changes automatically' do
      let(:additional_params) { { old_associations: {} } }
      let(:events_from_mappings) { [] }

      before do
        allow(Gitlab::WorkItems::Instrumentation::EventMappings)
          .to receive(:events_for)
          .with(work_item: work_item, old_associations: anything)
          .and_return(events_from_mappings)
      end

      context 'when EventMappings returns no events' do
        let(:events_from_mappings) { [] }

        it 'does not trigger any events' do
          expect { service.execute }.not_to trigger_internal_events
        end
      end

      context 'when EventMappings returns events' do
        let(:events_from_mappings) { %w[work_item_title_update work_item_description_update] }

        it 'triggers all returned events' do
          expect { service.execute }
            .to trigger_internal_events(
              'work_item_title_update',
              'work_item_description_update'
            ).with(expected_properties)
        end
      end
    end
  end
end
