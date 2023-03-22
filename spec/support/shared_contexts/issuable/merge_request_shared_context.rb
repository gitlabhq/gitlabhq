# frozen_string_literal: true

RSpec.shared_context 'merge request show action' do
  include Features::MergeRequestHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:merge_request) { create(:merge_request, :opened, source_project: project, author: user) }
  let_it_be(:note) { create(:note_on_merge_request, project: project, noteable: merge_request) }

  before do
    allow(view).to receive(:experiment_enabled?).and_return(false)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:can_admin_project_member?)
    assign(:project, project)
    assign(:merge_request, merge_request)
    assign(:note, note)
    assign(:noteable, merge_request)
    assign(:number_of_pipelines, 0)
    assign(:issuable_sidebar, serialize_issuable_sidebar(user, project, merge_request))

    preload_view_requirements(merge_request, note)
  end
end
