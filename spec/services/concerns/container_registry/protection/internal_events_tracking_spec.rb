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

  RSpec.shared_examples 'tracks internal event' do |event_name, additional_props = nil|
    it "tracks #{event_name}" do
      expected_params = {
        project: project,
        namespace: project.namespace,
        user: user
      }
      expected_params[:additional_properties] = additional_props if additional_props

      expect(service).to receive(:track_internal_event).with(event_name, **expected_params)

      subject
    end
  end

  describe '#track_tag_rule_creation' do
    let(:protection_rule) { create(:container_registry_protection_tag_rule, project: project) }

    subject { service.track_tag_rule_creation(protection_rule) }

    it_behaves_like 'tracks internal event',
      'create_container_registry_protected_tag_rule',
      { rule_type: 'mutable' }
  end

  describe '#track_tag_rule_deletion' do
    let(:protection_rule) { create(:container_registry_protection_tag_rule, project: project) }

    subject { service.track_tag_rule_deletion(protection_rule) }

    it_behaves_like 'tracks internal event',
      'delete_container_registry_protected_tag_rule',
      { rule_type: 'mutable' }
  end

  describe '#track_tag_rule_update' do
    let(:protection_rule) { create(:container_registry_protection_tag_rule, project: project) }

    subject { service.track_tag_rule_update(protection_rule) }

    it_behaves_like 'tracks internal event',
      'update_container_registry_protected_tag_rule',
      { rule_type: 'mutable' }
  end

  describe '#track_repository_rule_creation' do
    let(:protection_rule) { create(:container_registry_protection_rule, project: project) }

    subject { service.track_repository_rule_creation(protection_rule) }

    it_behaves_like 'tracks internal event', 'create_container_repository_protection_rule'
  end

  describe '#track_repository_rule_deletion' do
    let(:protection_rule) { create(:container_registry_protection_rule, project: project) }

    subject { service.track_repository_rule_deletion(protection_rule) }

    it_behaves_like 'tracks internal event', 'delete_container_repository_protection_rule'
  end

  describe '#track_event' do
    context 'with a TagRule' do
      let(:protection_rule) { create(:container_registry_protection_tag_rule, project: project) }

      subject { service.send(:track_event, 'test_event', protection_rule) }

      it_behaves_like 'tracks internal event', 'test_event', { rule_type: 'mutable' }
    end

    context 'with a repository protection Rule' do
      let(:protection_rule) { create(:container_registry_protection_rule, project: project) }

      subject { service.send(:track_event, 'test_event', protection_rule) }

      it_behaves_like 'tracks internal event', 'test_event'
    end
  end
end
