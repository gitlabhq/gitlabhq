# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/_archive.html.haml', feature_category: :groups_and_projects do
  describe 'Archive settings' do
    let_it_be(:user) { build_stubbed(:admin) }

    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- we need to run database queries here
    let_it_be_with_reload(:ancestor) { create(:group) }
    let_it_be_with_reload(:group) { create(:group, parent: ancestor) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    before do
      allow(view).to receive(:current_user).and_return(user)
    end

    context 'when group is archived' do
      before do
        group.namespace_settings.update!(archived: true)

        render 'groups/settings/archive', group: group
      end

      it 'renders #js-unarchive-settings' do
        expect(rendered).to have_selector('#js-unarchive-settings')
        expect(rendered).to have_selector('[data-resource-type="group"]')
        expect(rendered).to have_selector("[data-resource-id='#{group.id}']")
        expect(rendered).to have_selector("[data-resource-path='/#{group.full_path}']")
        expect(rendered).to have_selector('[data-ancestors-archived="false"]')
      end

      it 'does not render #js-archive-settings' do
        expect(rendered).not_to have_selector('#js-archive-settings')
      end
    end

    context 'when ancestor is archived' do
      before do
        ancestor.namespace_settings.update!(archived: true)

        render 'groups/settings/archive', group: group
      end

      it 'renders #js-unarchive-settings' do
        expect(rendered).to have_selector('#js-unarchive-settings')
        expect(rendered).to have_selector('[data-resource-type="group"]')
        expect(rendered).to have_selector("[data-resource-id='#{group.id}']")
        expect(rendered).to have_selector("[data-resource-path='/#{group.full_path}']")
        expect(rendered).to have_selector('[data-ancestors-archived="true"]')
      end

      it 'does not render #js-archive-settings' do
        expect(rendered).not_to have_selector('#js-archive-settings')
      end
    end

    context 'when group and ancestor is not archived' do
      before do
        render 'groups/settings/archive', group: group
      end

      it 'renders #js-archive-settings' do
        expect(rendered).to have_selector('#js-archive-settings')
        expect(rendered).to have_selector('[data-resource-type="group"]')
        expect(rendered).to have_selector("[data-resource-id='#{group.id}']")
        expect(rendered).to have_selector("[data-resource-path='/#{group.full_path}']")
      end

      it 'does not render #js-unarchive-settings' do
        expect(rendered).not_to have_selector('#js-unarchive-settings')
      end
    end
  end
end
