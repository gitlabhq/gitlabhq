# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'dashboard/projects/shared/_common.html.haml', feature_category: :groups_and_projects do
  let_it_be(:user) { build(:user) }

  before do
    view.lookup_context.prefixes = ['dashboard/projects']

    allow(view).to receive(:limited_counter_with_delimiter)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:time_ago_with_tooltip)
    allow(view).to receive(:empty_page).and_return('starred_empty_state')
  end

  context 'when feature :your_work_projects_vue is enabled' do
    before do
      stub_feature_flags(your_work_projects_vue: true)
    end

    context 'when projects exist' do
      before do
        assign(:projects, [build(:project, name: 'awesome stuff')])
        allow(view).to receive(:any_projects?).and_return(true)
        render
      end

      it 'renders #js-your-work-projects-app and not legacy project list' do
        render

        expect(rendered).to have_selector('#js-your-work-projects-app')
        expect(rendered).not_to render_template('dashboard/projects/_projects')
      end
    end

    context 'when projects do not exist' do
      before do
        allow(view).to receive(:any_projects?).and_return(false)
        render
      end

      it 'renders #js-your-work-projects-app and does not render HAML empty state' do
        render

        expect(rendered).to have_selector('#js-your-work-projects-app')
        expect(rendered).not_to render_template('dashboard/projects/_zero_authorized_projects')
      end
    end
  end

  context 'when feature :your_work_projects_vue is disabled' do
    before do
      stub_feature_flags(your_work_projects_vue: false)
    end

    context 'when projects exist' do
      before do
        assign(:projects, [build(:project, name: 'awesome stuff')])
        allow(view).to receive(:any_projects?).and_return(true)
        render
      end

      it 'shows the project the user is a member of in the list' do
        expect(rendered).to have_content('awesome stuff')
      end

      it 'shows the "New project" button' do
        expect(rendered).to have_link('New project')
      end

      it 'does not render starred_empty_state partial' do
        expect(rendered).not_to render_template('dashboard/projects/_starred_empty_state')
      end

      it 'does not render #js-your-work-projects-app' do
        expect(rendered).not_to have_selector('#js-your-work-projects-app')
      end
    end

    context 'when projects do not exist' do
      before do
        allow(view).to receive(:any_projects?).and_return(false)
        render
      end

      it 'does show the "New project" button' do
        expect(rendered).to have_link('New project')
      end

      it 'does render starred_empty_state partial' do
        expect(rendered).to render_template('dashboard/projects/_starred_empty_state')
      end

      it 'does not render #js-your-work-projects-app' do
        expect(rendered).not_to have_selector('#js-your-work-projects-app')
      end
    end
  end
end
