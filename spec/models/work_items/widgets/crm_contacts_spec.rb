# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::CrmContacts, feature_category: :team_planning do
  let_it_be(:project) { create(:project, group: create(:group)) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:issue_contact) { create(:issue_customer_relations_contact, :for_issue, issue: work_item) }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:crm_contacts) }
  end

  describe '.quick_action_commands' do
    subject { described_class.quick_action_commands }

    it { is_expected.to contain_exactly(:add_contacts, :remove_contacts) }
  end

  describe '.quick_action_params' do
    subject { described_class.quick_action_params }

    it { is_expected.to include(:contact_emails) }
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:crm_contacts) }
  end

  describe '#customer_relations_contacts' do
    subject { described_class.new(work_item).customer_relations_contacts }

    it { is_expected.to eq(work_item.customer_relations_contacts) }
  end
end
