# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveCustomerRelationContactsForEpicType, migration: :gitlab_main, feature_category: :service_desk do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:work_item_types) { table(:work_item_types) }
  let(:customer_relations_contacts) { table(:customer_relations_contacts) }
  let(:issue_customer_relations_contacts) { table(:issue_customer_relations_contacts) }

  let(:epic_work_item_type_id) { described_class::EPIC_WORK_ITEM_TYPE_ID }

  let!(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }
  let!(:namespace) { namespaces.create!(name: 'Test Group', path: 'test-group', organization_id: organization.id) }
  let!(:project) do
    projects.create!(name: 'Test Project', path: 'test-project', namespace_id: namespace.id,
      project_namespace_id: namespace.id, organization_id: organization.id)
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)
  end

  describe '#up' do
    let!(:epic_issue) do
      issues.create!(
        title: 'Epic Issue',
        project_id: project.id,
        namespace_id: namespace.id,
        work_item_type_id: epic_work_item_type_id
      )
    end

    let!(:regular_issue) do
      issues.create!(
        title: 'Regular Issue',
        project_id: project.id,
        namespace_id: namespace.id,
        work_item_type_id: 1
      )
    end

    let!(:epic_contacts) do
      [
        customer_relations_contacts.create!(group_id: namespace.id, first_name: 'Epic', last_name: 'Contact1',
          email: 'epic1@example.com'),
        customer_relations_contacts.create!(group_id: namespace.id, first_name: 'Epic', last_name: 'Contact2',
          email: 'epic2@example.com'),
        customer_relations_contacts.create!(group_id: namespace.id, first_name: 'Epic', last_name: 'Contact3',
          email: 'epic3@example.com')
      ]
    end

    let!(:regular_contact) do
      customer_relations_contacts.create!(group_id: namespace.id, first_name: 'Regular', last_name: 'Contact',
        email: 'regular@example.com')
    end

    before do
      epic_contacts.each do |contact|
        issue_customer_relations_contacts.create!(
          issue_id: epic_issue.id,
          contact_id: contact.id,
          namespace_id: namespace.id
        )
      end

      issue_customer_relations_contacts.create!(
        issue_id: regular_issue.id,
        contact_id: regular_contact.id,
        namespace_id: namespace.id
      )
    end

    it 'removes issue_customer_relations_contacts associated with epic work item type in batches' do
      expect do
        migrate!
      end.to make_queries_matching(
        /DELETE FROM issue_customer_relations_contacts/,
        2 # Should run 2 batches (3 epic contacts + 1 regular contact, batch size = 2)
      )
    end

    it 'removes only issue_customer_relations_contacts associated with epic work item type' do
      expect { migrate! }.to change { issue_customer_relations_contacts.count }.from(4).to(1)
        .and not_change { customer_relations_contacts.count }
    end

    it 'keeps issue_customer_relations_contacts for non-epic work item types' do
      expect { migrate! }.to change {
        issue_customer_relations_contacts.where(issue_id: epic_issue.id).count
      }.from(3).to(0)
        .and not_change { issue_customer_relations_contacts.where(issue_id: regular_issue.id).count }
    end

    context 'when there are no epic-related contacts' do
      before do
        customer_relations_contacts.delete_all
        issue_customer_relations_contacts.delete_all

        regular_contact_new = customer_relations_contacts.create!(
          group_id: namespace.id,
          first_name: 'Regular',
          last_name: 'Contact',
          email: 'regular@example.com'
        )

        issue_customer_relations_contacts.create!(
          issue_id: regular_issue.id,
          contact_id: regular_contact_new.id,
          namespace_id: namespace.id
        )
      end

      it 'does not remove any issue_customer_relations_contacts' do
        expect { migrate! }.not_to change { issue_customer_relations_contacts.count }
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { schema_migrate_down! }.not_to change { issue_customer_relations_contacts.count }
    end
  end
end
