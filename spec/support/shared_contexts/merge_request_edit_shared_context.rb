# frozen_string_literal: true

RSpec.shared_context 'merge request edit context' do
  let(:user)        { create(:user) }
  let(:user2)       { create(:user) }
  let!(:milestone)   { create(:milestone, project: target_project) }
  let!(:label)       { create(:label, project: target_project) }
  let!(:label2)      { create(:label, project: target_project, lock_on_merge: true) }
  let(:target_project) { create(:project, :public, :repository) }
  let(:source_project) { target_project }
  let(:merge_request) do
    create(
      :merge_request,
      source_project: source_project,
      target_project: target_project,
      source_branch: 'fix',
      target_branch: 'master'
    )
  end

  before do
    source_project.add_maintainer(user)
    target_project.add_maintainer(user)
    target_project.add_maintainer(user2)

    sign_in(user)
    visit edit_project_merge_request_path(target_project, merge_request)
  end
end
