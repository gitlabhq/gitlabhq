# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::InternalEventsTracking, feature_category: :container_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:service_class) do
    Class.new do
      include ContainerRegistry::Protection::InternalEventsTracking

      attr_reader :current_user

      def initialize(current_user)
        @current_user = current_user
      end
    end
  end

  let(:service) { service_class.new(user) }

  describe '#track_tag_rule_creation' do
    let(:protection_rule) { create(:container_registry_protection_tag_rule, project: project) }

    it 'tracks the tag rule creation event' do
      expect(service).to receive(:track_internal_event).with(
        'create_container_registry_protected_tag_rule',
        project: project,
        namespace: project.namespace,
        user: user,
        additional_properties: { rule_type: 'mutable' }
      )

      service.track_tag_rule_creation(protection_rule)
    end
  end

  describe '#track_tag_rule_deletion' do
    let(:protection_rule) { create(:container_registry_protection_tag_rule, project: project) }

    it 'tracks the tag rule deletion event' do
      expect(service).to receive(:track_internal_event).with(
        'delete_container_registry_protected_tag_rule',
        project: project,
        namespace: project.namespace,
        user: user,
        additional_properties: { rule_type: 'mutable' }
      )

      service.track_tag_rule_deletion(protection_rule)
    end
  end

  describe '#track_tag_rule_update' do
    let(:protection_rule) { create(:container_registry_protection_tag_rule, project: project) }

    it 'tracks the tag rule update event' do
      expect(service).to receive(:track_internal_event).with(
        'update_container_registry_protected_tag_rule',
        project: project,
        namespace: project.namespace,
        user: user,
        additional_properties: { rule_type: 'mutable' }
      )

      service.track_tag_rule_update(protection_rule)
    end
  end

  describe '#rule_type_for_tag_rule' do
    let(:protection_rule) { create(:container_registry_protection_tag_rule, project: project) }

    it 'returns the rule type from the protection rule' do
      expect(service.send(:rule_type_for_tag_rule, protection_rule)).to eq('mutable')
    end
  end

  describe '#track_protection_rule_event' do
    let(:protection_rule) { create(:container_registry_protection_tag_rule, project: project) }

    context 'when additional_properties is empty' do
      it 'tracks event without additional_properties' do
        expect(service).to receive(:track_internal_event).with(
          'test_event',
          project: project,
          namespace: project.namespace,
          user: user
        )

        service.send(:track_protection_rule_event, 'test_event', protection_rule, {})
      end
    end

    context 'when additional_properties is provided' do
      it 'tracks event with additional_properties' do
        expect(service).to receive(:track_internal_event).with(
          'test_event',
          project: project,
          namespace: project.namespace,
          user: user,
          additional_properties: { key: 'value' }
        )

        service.send(:track_protection_rule_event, 'test_event', protection_rule, { key: 'value' })
      end
    end
  end
end
