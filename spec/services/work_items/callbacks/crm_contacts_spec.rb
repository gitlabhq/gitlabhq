# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Callbacks::CrmContacts, feature_category: :service_desk do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, owners: user) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:contact) { create(:contact, group: group) }

  let(:default_params) { { contact_ids: [contact.id] } }
  let(:params) { default_params }
  let(:set_crm_contacts_service) { instance_double(::Issues::SetCrmContactsService, execute: nil) }

  subject(:callback) { described_class.new(issuable: work_item, current_user: user, params: params).after_save }

  before do
    allow(::Issues::SetCrmContactsService).to receive(:new).and_return(set_crm_contacts_service)
  end

  shared_examples 'does not call SetCrmContactsService' do
    it 'is not called' do
      callback

      expect(::Issues::SetCrmContactsService).not_to have_received(:new)
    end
  end

  shared_examples 'raises a WidgetError' do
    let(:error_class) { ::WorkItems::Widgets::BaseService::WidgetError }

    it { expect { callback }.to raise_error(error_class, message) }
  end

  context 'when work item belongs to a project' do
    it 'updates the contacts' do
      allow(::Issues::SetCrmContactsService).to receive(:new).and_call_original

      callback

      expect(work_item.customer_relations_contacts).to contain_exactly(contact)
    end
  end

  context 'when work item belongs to a group' do
    let(:work_item) { create(:work_item, :group_level, namespace: group) }

    it 'updates the contacts' do
      allow(::Issues::SetCrmContactsService).to receive(:new).and_call_original

      callback

      expect(work_item.customer_relations_contacts).to contain_exactly(contact)
    end
  end

  context 'when contact_ids param is missing' do
    let(:params) { { operation_mode: 'APPEND' } }

    it_behaves_like 'does not call SetCrmContactsService'
  end

  context 'when operation_mode param is invalid' do
    let(:params) { { operation_mode: 'BOB' } }

    it_behaves_like 'does not call SetCrmContactsService'
  end

  context 'when work item does not have a parent group' do
    let(:user_namespace_project) { build_stubbed(:project, namespace: user.namespace) }
    let(:work_item) { build_stubbed(:work_item, project: user_namespace_project) }
    let(:message) { 'Work item not supported' }

    it_behaves_like 'raises a WidgetError'
  end

  context 'when feature is disabled' do
    let(:work_item) { WorkItem.new(project: Project.new(group: create(:group, :crm_disabled))) }
    let(:message) { 'Feature disabled' }

    it_behaves_like 'raises a WidgetError'
  end

  context 'when SetCrmContactsService returns error response' do
    let(:message) { 'Something went wrong!' }

    before do
      allow(set_crm_contacts_service).to receive(:execute).and_return(ServiceResponse.error(message: message))
    end

    it_behaves_like 'raises a WidgetError'
  end
end
