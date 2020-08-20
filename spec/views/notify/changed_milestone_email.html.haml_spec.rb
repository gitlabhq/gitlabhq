# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/changed_milestone_email.html.haml' do
  let(:milestone) { create(:milestone, title: 'some-milestone') }
  let(:milestone_link) { milestone_url(milestone) }

  before do
    assign(:milestone, milestone)
    assign(:milestone_url, milestone_link)
  end

  context 'milestone without start and due dates' do
    it 'renders without date range' do
      render

      expect(rendered).to have_content('Milestone changed to some-milestone', exact: true)
      expect(rendered).to have_link('some-milestone', href: milestone_link)
    end
  end

  context 'milestone with start and due dates' do
    before do
      milestone.update!(start_date: '2018-01-01', due_date: '2018-12-31')
    end

    it 'renders with date range' do
      render

      expect(rendered).to have_content('Milestone changed to some-milestone (Jan 1, 2018–Dec 31, 2018)', exact: true)
      expect(rendered).to have_link('some-milestone', href: milestone_link)
    end
  end
end
