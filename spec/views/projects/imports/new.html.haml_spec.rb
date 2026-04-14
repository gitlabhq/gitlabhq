# frozen_string_literal: true

require "spec_helper"

RSpec.describe "projects/imports/new.html.haml", feature_category: :importers do
  let(:user) { create(:user) }

  context 'when import fails' do
    let(:project) { create(:project_empty_repo, :import_failed, import_type: :gitlab_project, import_source: '/var/opt/gitlab/gitlab-rails/shared/tmp/project_exports/uploads/t.tar.gz', import_url: 'https://example.com/repo.git') }

    before do
      project.import_state.update!(last_error: '<a href="http://googl.com">Foo</a>')
      sign_in(user)
      project.add_maintainer(user)
      assign(:project, project)
    end

    it "escapes HTML in import errors", :skip_html_escaped_tags_check do
      render

      expect(rendered).not_to have_link('Foo', href: "http://googl.com")
    end

    context 'for Vue component data' do
      it 'passes import_from_url when url is present' do
        render
        expect(rendered).to include("data-import-from-url=\"https://example.com/repo.git\"")
      end

      it 'passes ci_cd_only' do
        render
        expect(rendered).to include('data-ci-cd-only="false"')
      end

      it 'passes git_timeout' do
        render
        expect(rendered).to match(/data-git-timeout="[\d\w\s]+"/)
      end

      it 'passes has_repository_mirrors_feature' do
        render
        expect(rendered).to include('data-has-repository-mirrors-feature="false"')
      end
    end
  end
end
