require "spec_helper"

describe "projects/imports/new.html.haml" do
  let(:user) { create(:user) }

  context 'when import fails' do
    let(:project) { create(:project_empty_repo, import_status: :failed, import_error: '<a href="http://googl.com">Foo</a>', import_type: :gitlab_project, import_source: '/var/opt/gitlab/gitlab-rails/shared/tmp/project_exports/uploads/t.tar.gz', import_url: nil) }

    before do
      sign_in(user)
      project.add_master(user)
    end

    it "escapes HTML in import errors" do
      assign(:project, project)

      render

      expect(rendered).not_to have_link('Foo', href: "http://googl.com")
    end
  end
end
