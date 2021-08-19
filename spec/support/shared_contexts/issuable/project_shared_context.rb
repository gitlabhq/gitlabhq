# frozen_string_literal: true

RSpec.shared_context 'project show action' do
  let(:project) { create(:project, :repository) }
  let(:issue) { create(:issue, project: project, author: user) }
  let(:user) { create(:user) }

  before do
    assign(:project, project)
    assign(:issue, issue)
    assign(:noteable, issue)
    stub_template 'shared/issuable/_sidebar' => ''
    stub_template 'projects/issues/_discussion' => ''
    allow(view).to receive(:user_status).and_return('')
    allow(view).to receive(:can_admin_project_member?)
  end
end
