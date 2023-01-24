# frozen_string_literal: true

RSpec.shared_examples 'for each incident details route' do |example, tab_text:|
  before do
    sign_in(user)
    visit incident_path
  end

  context 'for /-/issues/:id route' do
    let(:incident_path) { project_issue_path(project, incident) }

    before do
      page.within('[data-testid="incident-tabs"]') { click_link tab_text }
    end

    it_behaves_like example
  end

  context 'for /-/issues/incident/:id route' do
    let(:incident_path) { incident_project_issues_path(project, incident) }

    before do
      page.within('[data-testid="incident-tabs"]') { click_link tab_text }
    end

    it_behaves_like example
  end
end
