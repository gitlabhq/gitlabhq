# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WorkItems::Instrumentation::TrackingService, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, developers: user) }
  let_it_be(:work_item) { create(:work_item, project: project) }

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
            event: nil
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
    end
  end

  describe '#execute', :clean_gitlab_redis_shared_state do
    context 'when event is nil' do
      let(:additional_params) { { event: nil } }

      it 'does not trigger any events and returns early' do
        expect(service).not_to receive(:track_internal_event)

        result = service.execute

        expect(result).to be_nil
      end
    end

    context 'when event is provided directly' do
      let(:additional_params) { { event: ::Gitlab::WorkItems::Instrumentation::EventActions::NOTE_DESTROY } }

      it 'triggers the single event' do
        expect { service.execute }
          .to trigger_internal_events('work_item_note_destroy')
          .with(expected_properties)
      end
    end
  end
end
