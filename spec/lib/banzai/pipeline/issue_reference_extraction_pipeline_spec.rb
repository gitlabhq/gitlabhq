# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::IssueReferenceExtractionPipeline, feature_category: :markdown do
  describe '.filters' do
    subject(:filters) { described_class.filters }

    it 'keeps the filters that issue extraction relies on' do
      expect(filters).to include(
        Banzai::Filter::MarkdownFilter,
        Banzai::Filter::SanitizationFilter,
        Banzai::Filter::References::IssueReferenceFilter,
        Banzai::Filter::References::WorkItemReferenceFilter,
        Banzai::Filter::References::ExternalIssueReferenceFilter
      )
    end

    it 'drops the reference filters that run after the issue ones' do
      expect(filters).not_to include(
        Banzai::Filter::References::CommitReferenceFilter,
        Banzai::Filter::References::CommitRangeReferenceFilter,
        Banzai::Filter::References::MilestoneReferenceFilter,
        Banzai::Filter::References::LabelReferenceFilter
      )
    end

    it 'keeps the reference filters that run before the issue ones' do
      expect(filters).to include(
        Banzai::Filter::References::UserReferenceFilter,
        Banzai::Filter::References::DesignReferenceFilter
      )
    end
  end
end
