# frozen_string_literal: true

RSpec.shared_context 'open merge request show action' do
  include Spec::Support::Helpers::Features::MergeRequestHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:note) { create(:note_on_merge_request, project: project, noteable: open_merge_request) }

  let(:open_merge_request) do
    create(:merge_request, :opened, source_project: project, author: user)
  end

  before do
    assign(:project, project)
    assign(:merge_request, open_merge_request)
    assign(:note, note)
    assign(:noteable, open_merge_request)
    assign(:notes, [])
    assign(:pipelines, Ci::Pipeline.none)
    assign(:issuable_sidebar, serialize_issuable_sidebar(user, project, open_merge_request))

    preload_view_requirements(open_merge_request, note)

    sign_in(user)
  end
end

RSpec.shared_context 'closed merge request show action' do
  include Devise::Test::ControllerHelpers
  include ProjectForksHelper
  include Spec::Support::Helpers::Features::MergeRequestHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:forked_project) { fork_project(project, user, repository: true) }
  let(:unlink_project) { Projects::UnlinkForkService.new(forked_project, user) }
  let(:note) { create(:note_on_merge_request, project: project, noteable: closed_merge_request) }

  let(:closed_merge_request) do
    create(:closed_merge_request,
           source_project: forked_project,
           target_project: project,
           author: user)
  end

  before do
    assign(:project, project)
    assign(:merge_request, closed_merge_request)
    assign(:commits_count, 0)
    assign(:note, note)
    assign(:noteable, closed_merge_request)
    assign(:notes, [])
    assign(:pipelines, Ci::Pipeline.none)
    assign(:issuable_sidebar, serialize_issuable_sidebar(user, project, closed_merge_request))

    preload_view_requirements(closed_merge_request, note)

    allow(view).to receive_messages(current_user: user,
                                    can?: true,
                                    current_application_settings: Gitlab::CurrentSettings.current_application_settings)
  end
end
