# frozen_string_literal: true

RSpec.shared_context 'merge request create context' do
  let(:user)        { create(:user) }
  let(:user2)       { create(:user) }
  let(:target_project) { create(:project, :public, :repository) }
  let(:source_project) { target_project }
  let!(:milestone)   { create(:milestone, project: target_project) }
  let!(:label)       { create(:label, project: target_project) }
  let!(:label2)      { create(:label, project: target_project) }

  before do
    source_project.add_maintainer(user)
    target_project.add_maintainer(user)
    target_project.add_maintainer(user2)

    sign_in(user)
    visit project_new_merge_request_path(
      target_project,
      merge_request: {
        source_project_id: source_project.id,
        target_project_id: target_project.id,
        source_branch: 'fix',
        target_branch: 'master'
      })
  end
end
