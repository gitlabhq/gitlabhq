# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/issues/_related_issues.html.haml', feature_category: :team_planning do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:issue) { build_stubbed(:issue, project: project) }

  context 'when current user cannot read issue link for the project' do
    before do
      allow(view).to receive(:can?).and_return(false)
    end

    it 'does not render the related issues root node' do
      render

      expect(rendered).not_to have_selector(".js-related-issues-root")
    end
  end

  context 'when current user can read issue link for the project' do
    before do
      allow(view).to receive(:can?).and_return(true)

      assign(:project, project)
      assign(:issue, issue)
    end

    it 'adds the report abuse path as a data attribute' do
      render

      expect(rendered).to have_selector(
        ".js-related-issues-root[data-wi-report-abuse-path=\"#{add_category_abuse_reports_path}\"]"
      )
    end
  end
end
