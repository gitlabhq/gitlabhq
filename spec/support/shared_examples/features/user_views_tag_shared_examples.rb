# frozen_string_literal: true

RSpec.shared_examples 'user views tag' do
  context 'when user views with the tag' do
    let(:project) { create(:project, :repository, :public) }
    let(:user) { create(:user) }
    let(:tag_name) { "stable" }
    let(:release_name) { 'ReleaseName' }
    let(:release_notes) { 'Release notes' }
    let!(:release) do
      create(:release, project: project, tag: tag_name, name: release_name, description: release_notes)
    end

    before do
      project.repository.add_tag(user, tag_name, project.default_branch_or_main)
      sign_in(user)
    end

    context 'and user is authorized to read release' do
      before do
        project.add_developer(user)
      end

      shared_examples 'shows tag' do
        it do
          visit tag_page

          expect(page).to have_content tag_name
          expect(page).to have_link(release_name, href: project_release_path(project, release))
        end
      end

      it_behaves_like 'shows tag'

      context 'when tag name contains a slash' do
        let(:tag_name) { "stable/v0.1" }

        it_behaves_like 'shows tag'
      end
    end

    context 'and user is not authorized to read release' do
      before do
        project.project_feature.update!(releases_access_level: Featurable::PRIVATE)
      end

      it 'hides release link and notes', :aggregate_failures do
        visit tag_page

        expect(page).not_to have_link(release_name, href: project_release_path(project, release))
        expect(page).not_to have_text(release_notes)
      end
    end
  end
end
