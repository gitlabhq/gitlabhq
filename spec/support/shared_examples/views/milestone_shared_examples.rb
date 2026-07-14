# frozen_string_literal: true

RSpec.shared_examples 'milestone empty states' do
  include Devise::Test::ControllerHelpers

  let_it_be(:user) { build(:user) }
  let(:empty_state) { 'Use milestones to track issues and merge requests over a fixed period of time' }

  before do
    assign(:projects, [])
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'with no milestones' do
    before do
      assign(:milestones, [])
      assign(:milestone_states, { opened: 0, closed: 0, all: 0 })
      render
    end

    it 'shows empty state' do
      expect(rendered).to have_content(empty_state)
    end

    it 'does not show tabs or searchbar' do
      expect(rendered).not_to have_link('Open')
      expect(rendered).not_to have_link('Closed')
      expect(rendered).not_to have_link('All')
    end
  end

  context 'with no open milestones' do
    before do
      allow(view).to receive(:milestone_path).and_return("/milestones/1")
      assign(:milestones, [])
      assign(:milestone_states, { opened: 0, closed: 1, all: 1 })
    end

    it 'shows tabs and searchbar', :aggregate_failures do
      render

      expect(rendered).not_to have_content(empty_state)
      expect(rendered).to have_link('Open')
      expect(rendered).to have_link('Closed')
      expect(rendered).to have_link('All')
    end

    it 'shows empty state' do
      render

      expect(rendered).to have_content('There are no open milestones')
    end
  end

  context 'with no closed milestones' do
    before do
      allow(view).to receive(:milestone_path).and_return("/milestones/1")
      allow(view).to receive(:params).and_return(state: 'closed')
      assign(:milestones, [])
      assign(:milestone_states, { opened: 1, closed: 0, all: 1 })
    end

    it 'shows tabs and searchbar', :aggregate_failures do
      render

      expect(rendered).not_to have_content(empty_state)
      expect(rendered).to have_link('Open')
      expect(rendered).to have_link('Closed')
      expect(rendered).to have_link('All')
    end

    it 'shows empty state on closed milestones' do
      render

      expect(rendered).to have_content('There are no closed milestones')
    end
  end
end
