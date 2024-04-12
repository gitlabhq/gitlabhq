# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::Projects::NotesPreloader, :request_store, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:issue) { create(:issue, project: project) }

  it 'preloads author access level and contributor status' do
    developer1 = create(:user, developer_of: project)
    developer2 = create(:user, developer_of: project)
    contributor1 = create(:user)
    contributor2 = create(:user)
    contributor3 = create(:user)

    create_merge_request_for(contributor1)
    create_note_for(developer1)
    create_note_for(contributor1)

    notes = issue.notes.preload(:author, :project).to_a

    control = ActiveRecord::QueryRecorder.new do
      preload_and_fetch_attributes(notes, developer1)
    end

    create_merge_request_for(contributor2)
    create_merge_request_for(contributor3)
    create_note_for(developer2)
    create_note_for(contributor2)
    create_note_for(developer1)
    create_note_for(contributor3)
    issue.reload

    notes = issue.notes.preload(:author, :project).to_a

    expect do
      preload_and_fetch_attributes(notes, developer1)
    end.not_to exceed_query_limit(control)
  end

  def create_note_for(user)
    create(:note, project: project, noteable: issue, author: user)
  end

  def create_merge_request_for(user)
    create(
      :merge_request,
      :merged,
      :simple,
      source_project: project,
      author: user,
      target_branch: project.default_branch.to_s
    )
  end

  def preload_and_fetch_attributes(notes, user)
    described_class.new(project, user).call(notes)

    notes.each { |n| n.contributor? && n.human_max_access }
  end
end
