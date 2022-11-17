# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/merge_requests/_close_reopen_draft_report_toggle.html.haml' do
  let_it_be(:merge_request) { create(:merge_request, state: :merged) }

  before do
    assign(:merge_request, merge_request)
    assign(:project, merge_request.target_project)

    allow(view).to receive(:moved_mr_sidebar_enabled?).and_return(true)
  end

  describe 'notifcations toggle' do
    context 'when mr merged and logged in' do
      it 'is present' do
        allow(view).to receive(:current_user).and_return(merge_request.author)

        render

        expect(rendered).to have_css('li', class: 'js-sidebar-subscriptions-widget-root')
      end
    end

    context 'when mr merged and not logged in' do
      it 'is not present' do
        render

        expect(rendered).not_to have_css('li', class: 'js-sidebar-subscriptions-widget-root')
      end
    end
  end
end
