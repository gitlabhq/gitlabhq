# frozen_string_literal: true

shared_context 'merge request show action' do
  include Devise::Test::ControllerHelpers
  include ProjectForksHelper

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

  def preload_view_requirements
    # This will load the status fields of the author of the note and merge request
    # to avoid queries in when rendering the view being tested.
    closed_merge_request.author.status
    note.author.status
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

    preload_view_requirements

    allow(view).to receive_messages(current_user: user,
                                    can?: true,
                                    current_application_settings: Gitlab::CurrentSettings.current_application_settings)
  end

  def serialize_issuable_sidebar(user, project, merge_request)
    MergeRequestSerializer
      .new(current_user: user, project: project)
      .represent(closed_merge_request, serializer: 'sidebar')
  end
end
