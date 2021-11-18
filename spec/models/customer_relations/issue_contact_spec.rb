# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::IssueContact do
  let_it_be(:issue_contact, reload: true) { create(:issue_customer_relations_contact) }

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

    let(:group) { build(:group) }
    let(:project) { build(:project, group: group) }
    let(:issue) { build(:issue, project: project) }
    let(:contact) { build(:contact, group: group) }
    let(:for_issue) { build(:issue_customer_relations_contact, :for_issue, issue: issue) }
    let(:for_contact) { build(:issue_customer_relations_contact, :for_contact, contact: contact) }

    it 'uses objects from the same group', :aggregate_failures do
      expect(stubbed.contact.group).to eq(stubbed.issue.project.group)
      expect(built.contact.group).to eq(built.issue.project.group)
      expect(created.contact.group).to eq(created.issue.project.group)
    end

    it 'builds using the same group', :aggregate_failures do
      expect(for_issue.contact.group).to eq(group)
      expect(for_contact.issue.project.group).to eq(group)
    end
  end

  describe 'validation' do
    let(:built) { build(:issue_customer_relations_contact, issue: create(:issue), contact: create(:contact)) }

    it 'fails when the contact group does not match the issue group' do
      expect(built).not_to be_valid
    end
  end
end
