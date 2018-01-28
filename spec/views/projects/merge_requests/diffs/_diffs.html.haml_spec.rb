require 'spec_helper'

describe 'projects/merge_requests/diffs/_diffs.html.haml' do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project, author: user) }

  before do
    allow(view).to receive(:url_for).and_return(controller.request.fullpath)

    assign(:merge_request, merge_request)
    assign(:environment, merge_request.environments_for(user).last)
    assign(:diffs, merge_request.diffs)
    assign(:merge_request_diffs, merge_request.diffs)
    assign(:diff_notes_disabled, true) # disable note creation
    assign(:use_legacy_diff_notes, false)
    assign(:grouped_diff_discussions, {})
    assign(:notes, [])
  end

  context 'for a commit' do
    let(:commit) { merge_request.commits.last }

    before do
      assign(:commit, commit)
    end

    it "shows the commit scope" do
      render

      expect(rendered).to have_content "Only comments from the following commit are shown below"
    end
  end
end
