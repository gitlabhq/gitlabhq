# frozen_string_literal: true

require 'spec_helper'

describe 'projects/issues/show' do
  let(:project) { create(:project, :repository) }
  let(:issue) { create(:issue, project: project, author: user) }
  let(:user) { create(:user) }

  before do
    assign(:project, project)
    assign(:issue, issue)
    assign(:noteable, issue)
    stub_template 'shared/issuable/_sidebar' => ''
    stub_template 'projects/issues/_discussion' => ''
    allow(view).to receive(:issuable_meta).and_return('')
  end

  context 'when the issue is closed' do
    before do
      allow(issue).to receive(:closed?).and_return(true)
    end

    it 'shows "Closed (moved)" if an issue has been moved' do
      allow(issue).to receive(:moved?).and_return(true)

      render

      expect(rendered).to have_selector('.status-box-issue-closed:not(.hidden)', text: 'Closed (moved)')
    end

    it 'shows "Closed" if an issue has not been moved' do
      render

      expect(rendered).to have_selector('.status-box-issue-closed:not(.hidden)', text: 'Closed')
    end
  end

  context 'when the issue is open' do
    before do
      allow(issue).to receive(:closed?).and_return(false)
      allow(issue).to receive(:disscussion_locked).and_return(false)
    end

    it 'shows "Open" if an issue has been moved' do
      render

      expect(rendered).to have_selector('.status-box-open:not(.hidden)', text: 'Open')
    end
  end
end
