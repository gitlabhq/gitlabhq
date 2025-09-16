# frozen_string_literal: true

require 'spec_helper'

LIMIT = 5
TOTAL_ISSUES = 30
TOTAL_ISSUES_AGGREGATE_VIEW = 5

RSpec.shared_examples 'embedded views (GLQL)' do
  context 'with a simple query displaying a table of issues' do
    let(:is_mac) { page.evaluate_script('navigator.platform').include?('Mac') }
    let(:modifier_key) { is_mac ? :command : :control }

    before_all do
      label = create(:label, project: project, name: 'glql')
      create_list(:issue, TOTAL_ISSUES, project: project, labels: [label])
    end

    before do
      stub_feature_flags(glql_load_on_click: false)
      refresh

      fill_in 'Title', with: 'GLQL view test'

      textarea = find 'textarea'
      textarea.send_keys "```glql\n"
      textarea.send_keys "title: All issues with label glql\n"
      textarea.send_keys "query: type = Issue and label = ~glql\n"
      textarea.send_keys "limit: #{LIMIT}\n"
      textarea.send_keys "```"

      # submit
      textarea.send_keys [modifier_key, :enter]
    end

    it 'renders embedded views properly' do
      expect(page).to have_content('All issues with label glql')
      expect(page).to have_css("[data-testid='list'] li", count: LIMIT)
    end

    it 'loads more issues on clicking the load more button' do
      click_on "Load 20 more"
      wait_for_requests
      expect(page).to have_css("[data-testid='list'] li", count: LIMIT + 20)

      click_on "Load 5 more"
      wait_for_requests
      expect(page).to have_css("[data-testid='list'] li", count: TOTAL_ISSUES)

      expect(page).not_to have_css('[data-testid="load-more-button"]')
    end
  end

  context 'with an aggregate query (with feature flag enabled)' do
    let(:is_mac) { page.evaluate_script('navigator.platform').include?('Mac') }
    let(:modifier_key) { is_mac ? :command : :control }

    before_all do
      label = create(:label, project: project, name: 'glql')
      create_list(:issue, TOTAL_ISSUES_AGGREGATE_VIEW, project: project, labels: [label])
    end

    before do
      stub_feature_flags(glql_load_on_click: false)
      stub_feature_flags(glql_aggregation: true)
      refresh

      fill_in 'Title', with: 'GLQL aggregate view test'

      textarea = find 'textarea'
      textarea.send_keys "```glql\n"
      textarea.send_keys "display: table\n"
      textarea.send_keys "title: Issues created in the last 7 days\n"
      textarea.send_keys "query: type = Issue and label = ~glql and created > -7d and created <= today()\n"
      textarea.send_keys "groupBy: timeSegment(1d) on createdAt\n"
      textarea.send_keys "aggregate: count\n"
      textarea.send_keys "```"

      # submit
      textarea.send_keys [modifier_key, :enter]
    end

    it 'renders the aggregate query properly' do
      expect(page).to have_content('Issues created in the last 7 days')
      expect(page).to have_css("[data-testid='column-0']", text: 'Created at')
      expect(page).to have_css("[data-testid='column-1']", text: 'Count')

      # shows the correct count for the last day
      expect(page).to have_css("[data-testid='glql-facade'] tr:last-child td:last-child",
        text: TOTAL_ISSUES_AGGREGATE_VIEW)
    end
  end
end
