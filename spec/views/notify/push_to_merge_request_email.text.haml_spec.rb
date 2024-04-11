# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'notify/push_to_merge_request_email.text.haml' do
  let(:user) { create(:user, developer_of: project) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project) }
  let(:new_commits) { project.repository.commits_between('be93687618e4b132087f430a4d8fc3a609c9b77c', '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51') }

  before do
    assign(:updated_by_user, user)
    assign(:project, project)
    assign(:merge_request, merge_request)
    assign(:existing_commits, [])
    assign(:new_commits, new_commits)
  end

  it_behaves_like 'renders plain text email correctly'
end
