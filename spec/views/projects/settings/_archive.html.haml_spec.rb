# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/settings/_archive.html.haml', feature_category: :groups_and_projects do
  describe 'Archive settings' do
    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- we need to run database queries here
    let_it_be(:user) { create(:user) }

    let_it_be_with_reload(:group) { create(:group, owners: [user]) }
    let_it_be_with_reload(:project) { create(:project, group: group) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    before do
      allow(view).to receive(:current_user).and_return(user)
    end

    context 'when group is not archived' do
      context 'when project is not archived' do
        it 'renders #js-archive-settings' do
          render 'projects/settings/archive', project: project

          expect(rendered).to have_selector('#js-archive-settings')
          expect(rendered).to have_selector('[data-resource-type="project"]')
          expect(rendered).to have_selector("[data-resource-id='#{project.id}']")
          expect(rendered).to have_selector("[data-resource-path='/#{project.full_path}']")
          expect(rendered)
            .to have_selector("[data-help-path='/help/user/project/working_with_projects.md#archive-a-project']")
        end

        it 'does not render #js-unarchive-settings' do
          render 'projects/settings/archive', project: project

          expect(rendered).not_to have_selector('#js-unarchive-settings')
        end
      end

      context 'when project is archived' do
        before do
          project.update!(archived: true)
        end

        it 'renders #js-unarchive-settings' do
          render 'projects/settings/archive', project: project

          expect(rendered).to have_selector('#js-unarchive-settings')
          expect(rendered).to have_selector('[data-resource-type="project"]')
          expect(rendered).to have_selector("[data-resource-id='#{project.id}']")
          expect(rendered).to have_selector("[data-resource-path='/#{project.full_path}']")
          expect(rendered).to have_selector('[data-ancestors-archived="false"]')
          expect(rendered)
            .to have_selector("[data-help-path='/help/user/project/working_with_projects.md#unarchive-a-project']")
        end

        it 'does not render #js-archive-settings' do
          render 'projects/settings/archive', project: project

          expect(rendered).not_to have_selector('#js-archive-settings')
        end
      end
    end

    context 'when group is archived' do
      before do
        group.archive
      end

      it 'renders #js-unarchive-settings' do
        render 'projects/settings/archive', project: project

        expect(rendered).to have_selector('#js-unarchive-settings')
        expect(rendered).to have_selector('[data-resource-type="project"]')
        expect(rendered).to have_selector("[data-resource-id='#{project.id}']")
        expect(rendered).to have_selector("[data-resource-path='/#{project.full_path}']")
        expect(rendered).to have_selector('[data-ancestors-archived="true"]')
        expect(rendered)
          .to have_selector("[data-help-path='/help/user/project/working_with_projects.md#unarchive-a-project']")
      end

      it 'does not render #js-archive-settings' do
        render 'projects/settings/archive', project: project

        expect(rendered).not_to have_selector('#js-archive-settings')
      end
    end
  end
end
