# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::LinkedWorkItem, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project) }

  describe 'validation' do
    let(:issue) { build(:issue, project: project) }
    let(:external_issue) { ExternalIssue.new('JIRA-1', project) }

    it 'is valid with only work_item' do
      item = described_class.new(work_item: issue, link_type: 'closes')

      expect(item.work_item).to eq(issue)
      expect(item.external_issue).to be_nil
    end

    it 'is valid with only external_issue' do
      item = described_class.new(external_issue: external_issue, link_type: 'mentioned')

      expect(item.external_issue).to eq(external_issue)
      expect(item.work_item).to be_nil
    end

    it 'raises when both work_item and external_issue are provided' do
      expect do
        described_class.new(work_item: issue, external_issue: external_issue, link_type: 'closes')
      end.to raise_error(ActiveModel::ValidationError)
    end

    it 'raises when neither work_item nor external_issue is provided' do
      expect do
        described_class.new(link_type: 'closes')
      end.to raise_error(ActiveModel::ValidationError)
    end
  end
end
