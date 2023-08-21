# frozen_string_literal: true

RSpec.shared_examples 'Deploy keys with protected tags' do
  let(:dropdown_sections_minus_deploy_keys) { all_dropdown_sections - ['Deploy Keys'] }

  context 'when deploy keys are enabled to this project' do
    let!(:deploy_key_1) { create(:deploy_key, title: 'title 1', projects: [project]) }
    let!(:deploy_key_2) { create(:deploy_key, title: 'title 2', projects: [project]) }

    context 'when only one deploy key can push' do
      before do
        deploy_key_1.deploy_keys_projects.first.update!(can_push: true)
      end

      it "shows all dropdown sections in the 'Allowed to create' main dropdown, with only one deploy key" do
        visit project_protected_tags_path(project)
        click_button('Add tag')

        find(".js-allowed-to-create").click
        wait_for_requests

        within('.dropdown-menu') do
          dropdown_headers = page.all('.dropdown-header').map(&:text)

          expect(dropdown_headers).to contain_exactly(*all_dropdown_sections)
          expect(page).to have_content('title 1')
          expect(page).not_to have_content('title 2')
        end
      end

      it "shows all sections in the 'Allowed to create' update dropdown" do
        create(:protected_tag, :no_one_can_create, project: project, name: 'v1.0.0')

        visit project_protected_tags_path(project)
        click_button('Add tag')

        within(".js-protected-tag-edit-form") do
          find(".js-allowed-to-create").click
          wait_for_requests

          dropdown_headers = page.all('.dropdown-header').map(&:text)

          expect(dropdown_headers).to contain_exactly(*all_dropdown_sections)
        end
      end
    end

    context 'when no deploy key can push' do
      it "just shows all sections but not deploy keys in the 'Allowed to create' dropdown" do
        visit project_protected_tags_path(project)
        click_button('Add tag')

        find(".js-allowed-to-create").click
        wait_for_requests

        within('.dropdown-menu') do
          dropdown_headers = page.all('.dropdown-header').map(&:text)

          expect(dropdown_headers).to contain_exactly(*dropdown_sections_minus_deploy_keys)
        end
      end
    end
  end
end
