# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/diffs/_file.html.haml', feature_category: :code_review_workflow do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- the partial renders Gitaly-backed diffs, so the repository must be persisted
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:commit) { project.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d') }
  let(:diff_file) { commit.diffs.diff_file_with_new_path('files/ruby/popen.rb') }

  before_all do
    project.add_maintainer(user)
  end

  before do
    assign(:project, project)
    assign(:merge_request, merge_request)
    allow(view).to receive(:current_user).and_return(user)
  end

  def render_view
    render partial: 'projects/diffs/file', locals: { diff_file: diff_file, project: project }
  end

  it 'links to the blob and the editor' do
    render_view

    expect(rendered).to have_css("a[href*='/-/blob/#{diff_file.content_sha}/files/ruby/popen.rb']")
    expect(rendered).to have_css("a[href*='/-/edit/#{merge_request.source_branch}/files/ruby/popen.rb']")
  end

  context 'when the file path contains traversal segments' do
    before do
      allow(diff_file).to receive(:path_traversal?).and_return(true)
    end

    it 'omits every URL built from the diff path' do
      render_view

      expect(rendered).not_to have_css("a[href*='/-/blob/']")
      expect(rendered).not_to have_css("a[href*='/-/edit/']")
      expect(rendered).not_to have_link('View file @ ')
    end
  end
end
