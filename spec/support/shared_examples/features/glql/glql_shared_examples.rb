# frozen_string_literal: true

require 'spec_helper'

LIMIT = 5
TOTAL_ISSUES = 30

RSpec.shared_examples 'embedded views (GLQL)' do
  let(:is_mac) { page.evaluate_script('navigator.platform').include?('Mac') }
  let(:modifier_key) { is_mac ? :command : :control }

  def submit_glql_view(title:, glql_lines:)
    stub_feature_flags(glql_load_on_click: false)
    refresh
    expect(page).to have_field('Title')

    fill_in 'Title', with: title

    textarea = find_field('Description')
    textarea.send_keys "```glql\n"
    glql_lines.each { |line| textarea.send_keys "#{line}\n" }
    textarea.send_keys "```"
    textarea.send_keys [modifier_key, :enter]

    expect(page).to have_css("[data-testid='glql-facade']")
  end

  context 'with a simple query displaying a table of issues' do
    before_all do
      label = create(:label, project: project, name: 'glql')
      create_list(:issue, TOTAL_ISSUES, project: project, labels: [label])
    end

    before do
      submit_glql_view(
        title: 'GLQL view test',
        glql_lines: [
          "title: All issues with label glql",
          "query: type = Issue and label = ~glql",
          "limit: #{LIMIT}"
        ]
      )
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

  context 'with a query displaying jobs' do
    let_it_be(:ci_pipeline) { create(:ci_pipeline, :success, project: project) }
    let_it_be(:ci_build) { create(:ci_build, :success, pipeline: ci_pipeline, name: 'rspec unit') }

    before do
      submit_glql_view(
        title: 'GLQL job query test',
        glql_lines: [
          "title: Jobs",
          "query: type = Job and project = \"#{project.full_path}\"",
          "fields: name, status",
          "limit: 5",
          "display: table"
        ]
      )
    end

    it 'renders the job query' do
      expect(page).to have_content('Jobs')
      expect(page).to have_css("[data-testid='glql-facade'] table")
      expect(page).to have_content('rspec unit')
    end
  end

  context 'with a query displaying pipelines' do
    let_it_be(:ci_pipeline) { create(:ci_pipeline, :success, project: project, name: 'Deploy pipeline') }

    before do
      submit_glql_view(
        title: 'GLQL pipeline query test',
        glql_lines: [
          "title: Pipelines",
          "query: type = Pipeline and project = \"#{project.full_path}\" and status = success",
          "fields: path, status",
          "limit: 5",
          "display: table"
        ]
      )
    end

    it 'renders the pipeline query' do
      expect(page).to have_content('Pipelines')
      expect(page).to have_css("[data-testid='glql-facade'] table")
      expect(page).to have_content("pipelines/#{ci_pipeline.id}")
    end
  end

  context 'with a query using aliased field names' do
    before_all do
      label = create(:label, project: project, name: 'alias-test')
      create(:issue, project: project, title: 'Alias test issue', description: 'alias content', labels: [label])
    end

    before do
      submit_glql_view(
        title: 'GLQL alias test',
        glql_lines: [
          "query: type = Issue and project = \"#{project.full_path}\" and label = ~alias-test",
          "fields: description, openedAt",
          "display: table"
        ]
      )
    end

    it 'renders aliased column headers with non-empty cell values', :aggregate_failures do
      table = find("[data-testid='glql-facade'] table")
      expect(table).to have_css('th', text: 'Description')
      expect(table).to have_css('th', text: 'Opened at')
      expect(table).to have_no_css('th', text: 'Description html')
      expect(table).to have_no_css('th', text: 'Created at')
      # Verify aliased fields resolved to actual values, not nil (rendered as "None")
      expect(table).to have_css('td', text: 'alias content')
      expect(table).to have_no_css('td', text: 'None')
    end
  end

  context 'with a query displaying projects' do
    let_it_be(:group) { create(:group) }
    let_it_be(:group_project) { create(:project, namespace: group) }

    before_all do
      group.add_maintainer(user)
    end

    before do
      submit_glql_view(
        title: 'GLQL project query test',
        glql_lines: [
          "title: Projects",
          "query: type = Project and namespace = \"#{group.full_path}\"",
          "fields: id, fullPath, webUrl",
          "limit: 10",
          "display: table"
        ]
      )
    end

    it 'renders the project query' do
      expect(page).to have_content('Projects')
      expect(page).to have_css("[data-testid='glql-facade'] table")
      expect(page).to have_text(group_project.full_path)
    end
  end
end
