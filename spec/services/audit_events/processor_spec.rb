# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Processor, feature_category: :audit_events do
  describe '.fetch' do
    context 'when audit_event_json is present' do
      let(:audit_event_json) { { id: 1, details: {} }.to_json }
      let(:parsed_audit_event) { instance_double(::AuditEvent) }

      it 'processes the JSON and returns an audit event' do
        expect(described_class).to receive(:fetch_from_json).with(audit_event_json).and_return(parsed_audit_event)

        expect(described_class.fetch(audit_event_json: audit_event_json)).to eq(parsed_audit_event)
      end
    end

    context 'when audit_event_id is present' do
      let(:audit_event_id) { 1 }
      let(:model_class) { '::AuditEvents::GroupAuditEvent' }
      let(:found_audit_event) { instance_double(::AuditEvents::GroupAuditEvent) }

      it 'finds the audit event by ID and returns it' do
        expect(described_class).to receive(:fetch_from_id).with(audit_event_id,
          model_class).and_return(found_audit_event)

        expect(described_class.fetch(audit_event_id: audit_event_id, model_class: model_class)).to eq(found_audit_event)
      end
    end

    context 'when both audit_event_id and audit_event_json are provided' do
      let(:audit_event_id) { 1 }
      let(:audit_event_json) { { id: 2, details: {} }.to_json }
      let(:parsed_audit_event) { instance_double(::AuditEvent) }

      it 'prioritizes audit_event_json and ignores audit_event_id' do
        expect(described_class).to receive(:fetch_from_json).with(audit_event_json).and_return(parsed_audit_event)
        expect(described_class).not_to receive(:fetch_from_id)

        expect(described_class.fetch(audit_event_id: audit_event_id,
          audit_event_json: audit_event_json)).to eq(parsed_audit_event)
      end
    end

    context 'when neither audit_event_id nor audit_event_json are provided' do
      it 'returns nil' do
        expect(described_class.fetch).to be_nil
      end
    end

    context 'when an error occurs' do
      let(:audit_event_id) { 1 }

      before do
        allow(described_class).to receive(:fetch_from_id).and_raise(StandardError.new('test error'))
      end

      it 'tracks the exception and returns nil' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception).with(
          an_instance_of(StandardError),
          hash_including(audit_event_id: audit_event_id, model_class: nil, audit_event_json: nil)
        )

        result = described_class.fetch(audit_event_id: audit_event_id)
        expect(result).to be_nil
      end
    end
  end

  describe '.fetch_from_id' do
    let(:audit_event_id) { 1 }

    context 'when model class is provided' do
      let(:model_class) { '::AuditEvents::GroupAuditEvent' }
      let(:group_audit_event) { instance_double(::AuditEvents::GroupAuditEvent) }

      it 'finds the audit event using the provided model class' do
        expect(::AuditEvents::GroupAuditEvent).to receive(:find).with(audit_event_id).and_return(group_audit_event)

        result = described_class.fetch_from_id(audit_event_id, model_class)
        expect(result).to eq(group_audit_event)
      end

      context 'when the record is not found' do
        before do
          allow(::AuditEvents::GroupAuditEvent).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
        end

        it 'tracks the error and returns nil' do
          expect(::Gitlab::ErrorTracking).to receive(:track_exception).with(
            an_instance_of(ActiveRecord::RecordNotFound),
            hash_including(audit_event_id: audit_event_id, model_class: model_class)
          )

          result = described_class.fetch_from_id(audit_event_id, model_class)
          expect(result).to be_nil
        end
      end
    end

    context 'when model class is not provided' do
      let(:audit_event) { instance_double(::AuditEvent) }

      it 'finds the audit event using the AuditEvent model' do
        expect(::AuditEvent).to receive(:find_by_id).with(audit_event_id).and_return(audit_event)

        result = described_class.fetch_from_id(audit_event_id, nil)
        expect(result).to eq(audit_event)
      end
    end
  end

  describe '.determine_audit_model_entity' do
    let(:group) { create(:group) }
    let(:project) { create(:project) }
    let(:user) { create(:user) }

    context 'with group_id present' do
      let(:audit_event_json) { { group_id: group.id }.with_indifferent_access }

      it 'returns GroupAuditEvent model and group entity' do
        allow(::Group).to receive(:find).with(group.id).and_return(group)

        model_class, entity = described_class.determine_audit_model_entity(audit_event_json)

        expect(model_class).to eq(::AuditEvents::GroupAuditEvent)
        expect(entity).to eq(group)
      end
    end

    context 'with project_id present' do
      let(:audit_event_json) { { project_id: project.id }.with_indifferent_access }

      it 'returns ProjectAuditEvent model and project entity' do
        allow(::Project).to receive(:find).with(project.id).and_return(project)

        model_class, entity = described_class.determine_audit_model_entity(audit_event_json)

        expect(model_class).to eq(::AuditEvents::ProjectAuditEvent)
        expect(entity).to eq(project)
      end
    end

    context 'with user_id present' do
      let(:audit_event_json) { { user_id: user.id }.with_indifferent_access }

      it 'returns UserAuditEvent model and user entity' do
        allow(::User).to receive(:find).with(user.id).and_return(user)

        model_class, entity = described_class.determine_audit_model_entity(audit_event_json)

        expect(model_class).to eq(::AuditEvents::UserAuditEvent)
        expect(entity).to eq(user)
      end
    end

    context 'with no entity ID present' do
      let(:audit_event_json) { { details: 'some details' }.with_indifferent_access }

      it 'returns InstanceAuditEvent model and instance symbol' do
        model_class, entity = described_class.determine_audit_model_entity(audit_event_json)

        expect(model_class).to eq(::AuditEvents::InstanceAuditEvent)
        expect(entity).to eq(:instance)
      end
    end

    context 'when entity is not found' do
      let(:non_existing_id) { non_existing_record_id }
      let(:audit_event_json) { { group_id: non_existing_id }.with_indifferent_access }

      it 'raises RecordNotFound error' do
        allow(::Group).to receive(:find).with(non_existing_id).and_raise(ActiveRecord::RecordNotFound)

        expect do
          described_class.determine_audit_model_entity(audit_event_json)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '.create_scoped_audit_event' do
    let(:audit_event_json) do
      {
        id: 123,
        group_id: 1,
        project_id: 2,
        user_id: 3,
        entity_type: 'Group',
        entity_id: 1,
        details: { custom_message: 'test message' }
      }.with_indifferent_access
    end

    context 'for GroupAuditEvent' do
      let(:model_class) { ::AuditEvents::GroupAuditEvent }

      it 'filters out excluded fields for group audit events' do
        event = described_class.create_scoped_audit_event(model_class, audit_event_json)

        expect(event).to be_a(::AuditEvents::GroupAuditEvent)
        expect(event.group_id).to eq(1)
        expect(event.attributes).not_to include('project_id')
        expect(event.attributes).not_to include('user_id')
        expect(event.attributes).not_to include('entity_type')
        expect(event.attributes).not_to include('entity_id')
      end
    end

    context 'for ProjectAuditEvent' do
      let(:model_class) { ::AuditEvents::ProjectAuditEvent }

      it 'filters out excluded fields for project audit events' do
        event = described_class.create_scoped_audit_event(model_class, audit_event_json)

        expect(event).to be_a(::AuditEvents::ProjectAuditEvent)
        expect(event.project_id).to eq(2)
        expect(event.attributes).not_to include('group_id')
        expect(event.attributes).not_to include('user_id')
        expect(event.attributes).not_to include('entity_type')
        expect(event.attributes).not_to include('entity_id')
      end
    end

    context 'for UserAuditEvent' do
      let(:model_class) { ::AuditEvents::UserAuditEvent }

      it 'filters out excluded fields for user audit events' do
        event = described_class.create_scoped_audit_event(model_class, audit_event_json)

        expect(event).to be_a(::AuditEvents::UserAuditEvent)
        expect(event.user_id).to eq(3)
        expect(event.attributes).not_to include('group_id')
        expect(event.attributes).not_to include('project_id')
        expect(event.attributes).not_to include('entity_type')
        expect(event.attributes).not_to include('entity_id')
      end
    end

    context 'for InstanceAuditEvent' do
      let(:model_class) { ::AuditEvents::InstanceAuditEvent }

      it 'filters out all entity fields for instance audit events' do
        event = described_class.create_scoped_audit_event(model_class, audit_event_json)

        expect(event).to be_a(::AuditEvents::InstanceAuditEvent)
        expect(event.attributes).not_to include('group_id')
        expect(event.attributes).not_to include('project_id')
        expect(event.attributes).not_to include('user_id')
        expect(event.attributes).not_to include('entity_type')
        expect(event.attributes).not_to include('entity_id')
      end
    end

    context 'for unknown model class' do
      # Create a test double that mimics ActiveRecord behavior
      let(:model_class) do
        Class.new do
          attr_reader :attributes

          def initialize(attrs = {})
            @attributes = attrs
            attrs.each do |key, value|
              define_singleton_method(key) { value }
            end
          end
        end
      end

      it 'only filters out entity_type and entity_id fields' do
        event = described_class.create_scoped_audit_event(model_class, audit_event_json)

        expect(event).to be_an_instance_of(model_class)
        expect(event.group_id).to eq(1)
        expect(event.project_id).to eq(2)
        expect(event.user_id).to eq(3)
        expect(event.attributes).not_to include('entity_type')
        expect(event.attributes).not_to include('entity_id')
      end
    end
  end

  describe '.fetch_from_json' do
    let(:group) { create(:group) }
    let(:author) { create(:user) }
    let(:base_json) do
      {
        author_id: author.id,
        entity_id: group.id,
        entity_type: 'Group',
        created_at: Time.current,
        details: { custom_message: 'test message' }
      }
    end

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(stream_audit_events_from_new_tables: true)
      end

      context 'with group_id present' do
        let(:audit_event_json) do
          base_json.merge(
            group_id: group.id
          ).to_json
        end

        it 'creates a GroupAuditEvent' do
          allow(described_class).to receive(:determine_audit_model_entity).and_return([::AuditEvents::GroupAuditEvent,
            group])
          allow(::Gitlab::Audit::FeatureFlags).to receive(:stream_from_new_tables?).with(group).and_return(true)

          result = described_class.fetch_from_json(audit_event_json)

          expect(result).to be_a(::AuditEvents::GroupAuditEvent)
        end
      end

      context 'with project_id present' do
        let(:project) { create(:project) }
        let(:audit_event_json) do
          base_json.merge(
            project_id: project.id
          ).to_json
        end

        it 'creates a ProjectAuditEvent' do
          allow(described_class).to receive(:determine_audit_model_entity).and_return([
            ::AuditEvents::ProjectAuditEvent, project
          ])
          allow(::Gitlab::Audit::FeatureFlags).to receive(:stream_from_new_tables?).with(project).and_return(true)

          result = described_class.fetch_from_json(audit_event_json)

          expect(result).to be_a(::AuditEvents::ProjectAuditEvent)
        end
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(stream_audit_events_from_new_tables: false)
        allow(described_class).to receive(:determine_audit_model_entity).and_return([::AuditEvents::GroupAuditEvent,
          group])
        allow(::Gitlab::Audit::FeatureFlags).to receive(:stream_from_new_tables?).with(group).and_return(false)
      end

      let(:audit_event_json) do
        base_json.merge(
          group_id: group.id
        ).to_json
      end

      it 'creates a base AuditEvent' do
        result = described_class.fetch_from_json(audit_event_json)

        expect(result).to be_a(::AuditEvent)
      end

      it 'filters out group_id, project_id, and user_id fields' do
        result = described_class.fetch_from_json(audit_event_json)

        expect(result.attributes).not_to include('group_id')
        expect(result.attributes).not_to include('project_id')
        expect(result.attributes).not_to include('user_id')
      end
    end

    context 'when JSON parsing fails' do
      let(:invalid_json) { '{invalid_json' }

      it 'tracks the exception and returns nil' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception).with(
          an_instance_of(JSON::ParserError),
          hash_including(audit_event_json: invalid_json)
        )

        result = described_class.fetch_from_json(invalid_json)
        expect(result).to be_nil
      end
    end

    context 'when entity lookup fails' do
      let(:non_existing_id) { non_existing_record_id }
      let(:audit_event_json) do
        {
          group_id: non_existing_id,
          author_id: create(:user).id,
          entity_id: non_existing_id,
          entity_type: 'Group',
          created_at: Time.current
        }.to_json
      end

      it 'tracks the exception and returns nil' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception).with(
          an_instance_of(ActiveRecord::RecordNotFound),
          hash_including(audit_event_json: a_string_matching(/#{non_existing_id}/))
        )

        result = described_class.fetch_from_json(audit_event_json)
        expect(result).to be_nil
      end
    end
  end
end
