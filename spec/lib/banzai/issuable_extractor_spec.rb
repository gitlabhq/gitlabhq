# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::IssuableExtractor, feature_category: :markdown do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let(:extractor) { described_class.new(Banzai::RenderContext.new(project, user)) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:group_work_item) { create(:work_item, namespace: group) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let(:issue_link) do
    html_to_node(
      "<a href='' data-issue='#{issue.id}' data-reference-type='issue' class='gfm'>text</a>"
    )
  end

  let(:work_item_link) do
    html_to_node(
      "<a href='' data-work-item='#{work_item.id}' data-reference-type='work_item' class='gfm'>text</a>"
    )
  end

  let(:group_work_item_link) do
    html_to_node(
      "<a href='' data-work-item='#{group_work_item.id}' data-reference-type='work_item' class='gfm'>text</a>"
    )
  end

  let(:merge_request_link) do
    html_to_node(
      "<a href='' data-merge-request='#{merge_request.id}' data-reference-type='merge_request' class='gfm'>text</a>"
    )
  end

  def html_to_node(html)
    Nokogiri::HTML.fragment(
      html
    ).children[0]
  end

  it 'returns instances of issuables for nodes with references' do
    result = extractor.extract([issue_link, work_item_link, group_work_item_link, merge_request_link])

    expect(result).to eq(
      issue_link => issue,
      work_item_link => work_item,
      group_work_item_link => group_work_item,
      merge_request_link => merge_request
    )
  end

  describe 'caching', :request_store do
    it 'saves records to cache' do
      extractor.extract([issue_link, work_item_link, group_work_item_link, merge_request_link])

      second_call_queries = ActiveRecord::QueryRecorder.new do
        extractor.extract([issue_link, work_item_link, group_work_item_link, merge_request_link])
      end

      expect(second_call_queries.count).to eq 0
    end
  end
end
