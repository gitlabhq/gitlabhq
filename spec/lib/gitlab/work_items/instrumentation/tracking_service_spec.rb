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

  describe '.current_source' do
    after do
      ::Current.token_info = nil
    end

    context 'when there is no token info in the current context' do
      before do
        ::Current.token_info = nil
      end

      it 'returns the internal source' do
        expect(described_class.current_source).to eq(described_class::SOURCE_INTERNAL)
      end
    end

    context 'when the current token has the ai_workflows scope' do
      before do
        ::Current.token_info = { token_scopes: [:ai_workflows] }
      end

      it 'returns the ai_workflows source' do
        expect(described_class.current_source).to eq(described_class::SOURCE_AI_WORKFLOWS)
      end
    end

    context 'when the current token has the ai_workflows scope as a string' do
      before do
        ::Current.token_info = { token_scopes: ['ai_workflows'] }
      end

      it 'returns the ai_workflows source' do
        expect(described_class.current_source).to eq(described_class::SOURCE_AI_WORKFLOWS)
      end
    end

    context 'when the current token has only the api scope' do
      before do
        ::Current.token_info = { token_scopes: [:api] }
      end

      it 'returns the api source' do
        expect(described_class.current_source).to eq(described_class::SOURCE_API)
      end
    end
  end

  describe '.track', :clean_gitlab_redis_shared_state do
    let_it_be(:namespace) { create(:namespace) }

    let(:valid_properties) do
      {
        user: user,
        namespace: namespace,
        project: nil,
        additional_properties: { property: 'Developer' }
      }
    end

    context 'with a valid non-work-item event' do
      it 'triggers the internal event with the given properties' do
        expect do
          described_class.track(
            event: Gitlab::WorkItems::Instrumentation::EventActions::SAVED_VIEW_CREATE,
            properties: valid_properties
          )
        end.to trigger_internal_events('saved_view_create').with(valid_properties)
      end
    end

    context 'with a work item event' do
      it 'does not trigger any event' do
        expect do
          described_class.track(
            event: Gitlab::WorkItems::Instrumentation::EventActions::CREATE,
            properties: valid_properties
          )
        end.not_to trigger_internal_events
      end
    end

    context 'when project is present' do
      it 'passes project through to the internal event' do
        properties_with_project = valid_properties.merge(project: project)

        expect do
          described_class.track(
            event: Gitlab::WorkItems::Instrumentation::EventActions::SAVED_VIEW_UPDATE,
            properties: properties_with_project
          )
        end.to trigger_internal_events('saved_view_update').with(properties_with_project)
      end
    end
  end

  describe '.track_saved_view', :clean_gitlab_redis_shared_state do
    let_it_be(:group) { create(:group, developers: user) }
    let_it_be(:group_project) { create(:project, group: group) }
    let_it_be(:group_saved_view) { create(:saved_view, namespace: group) }
    let_it_be(:project_saved_view) { create(:saved_view, namespace: group_project.project_namespace) }

    let(:event) { Gitlab::WorkItems::Instrumentation::EventActions::SAVED_VIEW_DELETE }

    context 'when the saved view belongs to a project namespace' do
      it 'triggers the event with the owning project' do
        expect do
          described_class.track_saved_view(event: event, saved_view: project_saved_view, user: user)
        end.to trigger_internal_events('saved_view_delete').with(
          user: user,
          namespace: group_project.project_namespace,
          project: group_project,
          additional_properties: { property: 'Developer' }
        )
      end
    end

    context 'when the saved view belongs to a group namespace' do
      it 'triggers the event with a nil project' do
        expect do
          described_class.track_saved_view(event: event, saved_view: group_saved_view, user: user)
        end.to trigger_internal_events('saved_view_delete').with(
          user: user,
          namespace: group,
          project: nil,
          additional_properties: { property: 'Developer' }
        )
      end
    end

    context 'when the user has a different role in the namespace' do
      let_it_be(:maintainer) { create(:user, maintainer_of: group) }

      it 'derives the property from the namespace user role' do
        expect do
          described_class.track_saved_view(event: event, saved_view: group_saved_view, user: maintainer)
        end.to trigger_internal_events('saved_view_delete').with(
          user: maintainer,
          namespace: group,
          project: nil,
          additional_properties: { property: 'Maintainer' }
        )
      end
    end

    context 'when the user is not a member of the namespace' do
      let_it_be(:non_member) { create(:user) }

      it 'derives a nil property from the namespace user role' do
        expect do
          described_class.track_saved_view(event: event, saved_view: group_saved_view, user: non_member)
        end.to trigger_internal_events('saved_view_delete').with(
          user: non_member,
          namespace: group,
          project: nil,
          additional_properties: { property: nil }
        )
      end
    end
  end
end
