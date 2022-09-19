# frozen_string_literal: true

require "spec_helper"

RSpec.describe "projects/imports/new.html.haml" do
  let(:user) { create(:user) }

  context 'when import fails' do
    let(:project) { create(:project_empty_repo, :import_failed, import_type: :gitlab_project, import_source: '/var/opt/gitlab/gitlab-rails/shared/tmp/project_exports/uploads/t.tar.gz', import_url: nil) }

    before do
      project.import_state.update!(last_error: '<a href="http://googl.com">Foo</a>')
      sign_in(user)
      project.add_maintainer(user)
    end

    it "escapes HTML in import errors", :skip_html_escaped_tags_check do
      assign(:project, project)

      render

      expect(rendered).not_to have_link('Foo', href: "http://googl.com")
    end
  end
end
