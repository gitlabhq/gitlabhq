# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::PropagateIntegrationService do
  describe '.propagate' do
    include JiraServiceHelper

    before do
      stub_jira_service_test
    end

    let_it_be(:project) { create(:project) }
    let!(:instance_integration) do
      JiraService.create!(
        instance: true,
        active: true,
        push_events: true,
        url: 'http://update-jira.instance.com',
        username: 'user',
        password: 'secret'
      )
    end

    let!(:inherited_integration) do
      JiraService.create!(
        project: create(:project),
        inherit_from_id: instance_integration.id,
        instance: false,
        active: true,
        push_events: false,
        url: 'http://jira.instance.com',
        username: 'user',
        password: 'secret'
      )
    end

    let!(:not_inherited_integration) do
      JiraService.create!(
        project: project,
        inherit_from_id: nil,
        instance: false,
        active: true,
        push_events: false,
        url: 'http://jira.instance.com',
        username: 'user',
        password: 'secret'
      )
    end

    let!(:different_type_inherited_integration) do
      BambooService.create!(
        project: project,
        inherit_from_id: instance_integration.id,
        instance: false,
        active: true,
        push_events: false,
        bamboo_url: 'http://gitlab.com',
        username: 'mic',
        password: 'password',
        build_key: 'build'
      )
    end

    context 'with inherited integration' do
      let(:integration) { inherited_integration }

      it 'calls to PropagateIntegrationProjectWorker' do
        expect(PropagateIntegrationInheritWorker).to receive(:perform_async)
          .with(instance_integration.id, inherited_integration.id, inherited_integration.id)

        described_class.propagate(instance_integration)
      end
    end

    context 'with a project without integration' do
      let!(:another_project) { create(:project) }

      it 'calls to PropagateIntegrationProjectWorker' do
        expect(PropagateIntegrationProjectWorker).to receive(:perform_async)
          .with(instance_integration.id, another_project.id, another_project.id)

        described_class.propagate(instance_integration)
      end
    end

    context 'with a group without integration' do
      let!(:group) { create(:group) }

      it 'calls to PropagateIntegrationProjectWorker' do
        expect(PropagateIntegrationGroupWorker).to receive(:perform_async)
          .with(instance_integration.id, group.id, group.id)

        described_class.propagate(instance_integration)
      end
    end
  end
end
