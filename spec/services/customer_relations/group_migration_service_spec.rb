# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::GroupMigrationService, feature_category: :service_desk do
  let(:old_group) { create(:group) }
  let(:new_group) { create(:group) }
  let(:was_crm_source) { true }
  let(:service) { described_class.new(old_group.id, new_group.id, was_crm_source) }

  let!(:duplicate_organization) { create(:crm_organization, group: old_group, name: "Organization A") }
  let!(:unique_organization) { create(:crm_organization, group: old_group, name: "Organization B") }
  let!(:duplicate_contact) do
    create(:contact, group: old_group, organization: duplicate_organization, email: "duplicate_contact@example.com")
  end

  let!(:unique_contact) do
    create(:contact, group: old_group, organization: unique_organization, email: "unique_contact@example.com")
  end

  let!(:existing_organization) { create(:crm_organization, group: new_group, name: "Organization A") }
  let!(:existing_contact) do
    create(:contact, group: new_group, organization: existing_organization, email: "duplicate_contact@example.com")
  end

  describe '#execute' do
    it "copies unique organizations and contacts to the new group" do
      service.execute

      expect(CustomerRelations::Organization.where(group_id: new_group.id).count).to eq(2)
      expect(CustomerRelations::Organization.where(group_id: new_group.id).pluck(:name))
        .to include("Organization A", "Organization B")

      expect(CustomerRelations::Contact.where(group_id: new_group.id).count).to eq(2)
      expect(CustomerRelations::Contact.where(group_id: new_group.id).pluck(:email))
        .to include("duplicate_contact@example.com", "unique_contact@example.com")
    end

    it 'updates the issues with the contact_ids from the new group' do
      duplicate_issue_contact = create(:issue_customer_relations_contact, :for_contact, contact: duplicate_contact)
      unique_issue_contact = create(:issue_customer_relations_contact, :for_contact, contact: unique_contact)

      service.execute

      expect { duplicate_issue_contact.reload }.to change { duplicate_issue_contact.contact_id }
        .from(duplicate_contact.id).to(existing_contact.id)
      expect { unique_issue_contact.reload }.not_to change { unique_issue_contact.contact.email }
    end

    context 'when was_crm_source flag is true' do
      it 'deletes the organizations and contacts from the old group' do
        service.execute

        expect(CustomerRelations::Organization.where(group_id: old_group.id)).to be_empty
        expect(CustomerRelations::Contact.where(group_id: old_group.id)).to be_empty
      end
    end

    context 'when was_crm_source flag is false' do
      let(:was_crm_source) { false }

      it 'leaves the organizations and contacts in the old group' do
        service.execute

        expect(CustomerRelations::Organization.where(group_id: old_group.id).count).to eq(2)
        expect(CustomerRelations::Contact.where(group_id: old_group.id).count).to eq(2)
      end
    end
  end
end
