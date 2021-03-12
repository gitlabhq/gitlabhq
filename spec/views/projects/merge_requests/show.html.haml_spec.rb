# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/merge_requests/show.html.haml', :aggregate_failures do
  include_context 'merge request show action'

  before do
    merge_request.reload
  end

  context 'when the merge request is open' do
    it 'shows the "Mark as draft" button' do
      render

      expect(rendered).to have_css('a', visible: true, text: 'Mark as draft')
      expect(rendered).to have_css('a', visible: false, text: 'Reopen')
      expect(rendered).to have_css('a', visible: true, text: 'Close')
    end
  end

  context 'when the merge request is closed' do
    before do
      merge_request.close!
    end

    it 'shows the "Reopen" button' do
      render

      expect(rendered).not_to have_css('a', visible: true, text: 'Mark as draft')
      expect(rendered).to have_css('a', visible: true, text: 'Reopen')
      expect(rendered).to have_css('a', visible: false, text: 'Close')
    end

    context 'when source project does not exist' do
      it 'does not show the "Reopen" button' do
        allow(merge_request).to receive(:source_project).and_return(nil)

        render

        expect(rendered).to have_css('a', visible: false, text: 'Reopen')
        expect(rendered).to have_css('a', visible: false, text: 'Close')
      end
    end
  end
end
