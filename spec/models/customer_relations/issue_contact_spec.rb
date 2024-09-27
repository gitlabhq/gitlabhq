# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::IssueContact, feature_category: :team_planning do
  let_it_be(:issue_contact, reload: true) { create(:issue_customer_relations_contact) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:subgroup_project) { create(:project, group: subgroup) }
  let_it_be(:issue) { create(:issue, project: project) }

  subject { issue_contact }

  it { expect(subject).to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:issue).required }
    it { is_expected.to belong_to(:contact).required }
  end

  describe 'factory' do
    let(:built) { build(:issue_customer_relations_contact) }
    let(:stubbed) { build_stubbed(:issue_customer_relations_contact) }
    let(:created) { create(:issue_customer_relations_contact) }

    let(:contact) { build(:contact, group: group) }
    let(:for_issue) { build(:issue_customer_relations_contact, :for_issue, issue: issue) }
    let(:for_contact) { build(:issue_customer_relations_contact, :for_contact, contact: contact) }

    context 'for root groups' do
      it 'uses objects from the same group', :aggregate_failures do
        expect(stubbed.contact.group).to eq(stubbed.issue.project.group)
        expect(built.contact.group).to eq(built.issue.project.group)
        expect(created.contact.group).to eq(created.issue.project.group)
      end
    end

    context 'for subgroups' do
      it 'builds using the root ancestor' do
        expect(for_issue.contact.group).to eq(group)
      end
    end
  end

  describe 'validation' do
    it 'fails when the contact group is unrelated to the issue group' do
      built = build(:issue_customer_relations_contact, issue: create(:issue), contact: create(:contact))

      expect(built).not_to be_valid
    end

    it 'succeeds when the contact belongs to a root group and is the same as the issue group' do
      built = build(:issue_customer_relations_contact, issue: create(:issue, project: project), contact: create(:contact, group: group))

      expect(built).to be_valid
    end

    it 'succeeds when the contact belongs to a root group and it is an ancestor of the issue group' do
      built = build(:issue_customer_relations_contact, issue: create(:issue, project: subgroup_project), contact: create(:contact, group: group))

      expect(built).to be_valid
    end

    it 'succeeds when the contact belongs to the issue CRM group that is not an ancestor' do
      new_contact = create(:contact)
      new_group = create(:group)
      create(:crm_settings, group: new_group, source_group: new_contact.group)
      new_project = build_stubbed(:project, group: new_group)
      new_issue = build_stubbed(:issue, project: new_project)

      built = build(:issue_customer_relations_contact, issue: new_issue, contact: new_contact)

      expect(built).to be_valid
    end
  end

  describe '#self.find_contact_ids_by_emails' do
    let_it_be(:for_issue) { create_list(:issue_customer_relations_contact, 2, :for_issue, issue: issue) }
    let_it_be(:not_for_issue) { create_list(:issue_customer_relations_contact, 2) }

    it 'returns ids of contacts from issue' do
      contact_ids = described_class.find_contact_ids_by_emails(issue.id, for_issue.map(&:contact).pluck(:email))

      expect(contact_ids).to match_array(for_issue.pluck(:contact_id))
    end

    it 'does not return ids of contacts from other issues' do
      contact_ids = described_class.find_contact_ids_by_emails(issue.id, not_for_issue.map(&:contact).pluck(:email))

      expect(contact_ids).to be_empty
    end

    it 'raises ArgumentError when called with too many emails' do
      too_many_emails = described_class::MAX_PLUCK + 1
      expect { described_class.find_contact_ids_by_emails(issue.id, Array(0..too_many_emails)) }.to raise_error(ArgumentError)
    end
  end

  describe '.delete_for_project' do
    let_it_be(:issue_contacts) { create_list(:issue_customer_relations_contact, 3, :for_issue, issue: create(:issue, project: project)) }

    it 'destroys all issue_contacts for project' do
      expect { described_class.delete_for_project(project.id) }.to change { described_class.count }.by(-3)
    end
  end

  describe '.delete_for_group' do
    let(:project_for_root_group) { create(:project, group: group) }

    it 'destroys all issue_contacts for projects in group and subgroups' do
      create_list(:issue_customer_relations_contact, 2, :for_issue, issue: create(:issue, project: project))
      create_list(:issue_customer_relations_contact, 2, :for_issue, issue: create(:issue, project: project_for_root_group))
      create(:issue_customer_relations_contact)

      expect { described_class.delete_for_group(group) }.to change { described_class.count }.by(-4)
    end
  end
end
