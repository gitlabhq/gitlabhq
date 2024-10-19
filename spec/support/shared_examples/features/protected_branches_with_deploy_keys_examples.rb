# frozen_string_literal: true

RSpec.shared_examples 'deploy keys with protected branches' do
  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  let(:dropdown_sections_minus_deploy_keys) { all_dropdown_sections - ['Deploy keys'] }

  context 'when deploy keys are enabled to this project' do
    let_it_be(:write_access_key) { create(:deploy_key, user: user, write_access_to: project) }
    let_it_be(:readonly_access_key) { create(:deploy_key, user: user, readonly_access_to: project) }

    context 'when only one deploy key can push' do
      it "shows all dropdown sections in the 'Allowed to push' main dropdown, with only one deploy key" do
        visit project_protected_branches_path(project)

        click_button 'Add protected branch'
        find(".js-allowed-to-push").click
        wait_for_requests

        within('[data-testid="allowed-to-push-dropdown"]') do
          dropdown_headers = page.all('.dropdown-header').map(&:text)

          expect(dropdown_headers).to contain_exactly(*all_dropdown_sections)
          expect(page).to have_content(write_access_key.title)
          expect(page).not_to have_content(readonly_access_key.title)
        end
      end

      it "shows all sections but not deploy keys in the 'Allowed to merge' main dropdown" do
        visit project_protected_branches_path(project)

        click_button 'Add protected branch'
        find(".js-allowed-to-merge").click
        wait_for_requests

        within('[data-testid="allowed-to-merge-dropdown"]') do
          dropdown_headers = page.all('.dropdown-header').map(&:text)

          expect(dropdown_headers).to contain_exactly(*dropdown_sections_minus_deploy_keys)
        end
      end

      it "shows all sections in the 'Allowed to push' update dropdown" do
        create(:protected_branch, :no_one_can_push, project: project, name: 'master')

        visit project_protected_branches_path(project)

        within(".js-protected-branch-edit-form") do
          find(".js-allowed-to-push").click
          wait_for_requests

          dropdown_headers = page.all('.dropdown-header').map(&:text)

          expect(dropdown_headers).to contain_exactly(*all_dropdown_sections)
        end
      end

      context 'when deploy key is already selected for protected branch' do
        let(:protected_branch) { create(:protected_branch, :no_one_can_push, project: project, name: 'master') }

        before do
          create(:protected_branch_push_access_level, protected_branch: protected_branch, deploy_key: write_access_key)
        end

        it 'displays a preselected deploy key' do
          visit project_protected_branches_path(project)

          within(".js-protected-branch-edit-form") do
            find(".js-allowed-to-push").click
            wait_for_requests

            within('[data-testid="deploy_key-dropdown-item"]') do
              deploy_key_checkbox = find('[data-testid="dropdown-item-checkbox"]')
              expect(deploy_key_checkbox).to have_no_css("gl-invisible")
            end
          end
        end
      end
    end

    context 'when no deploy key can push' do
      before_all do
        write_access_key.deploy_keys_projects.first.update!(can_push: false)
      end

      it "just shows all sections but not deploy keys in the 'Allowed to push' dropdown" do
        visit project_protected_branches_path(project)

        click_button 'Add protected branch'
        find(".js-allowed-to-push").click
        wait_for_requests

        within('[data-testid="allowed-to-push-dropdown"]') do
          dropdown_headers = page.all('.dropdown-header').map(&:text)

          expect(dropdown_headers).to contain_exactly(*dropdown_sections_minus_deploy_keys)
        end
      end

      it "just shows all sections but not deploy keys in the 'Allowed to push' update dropdown" do
        create(:protected_branch, :no_one_can_push, project: project, name: 'master')

        visit project_protected_branches_path(project)

        within(".js-protected-branch-edit-form") do
          find(".js-allowed-to-push").click
          wait_for_requests

          dropdown_headers = page.all('.dropdown-header').map(&:text)

          expect(dropdown_headers).to contain_exactly(*dropdown_sections_minus_deploy_keys)
        end
      end
    end
  end
end
