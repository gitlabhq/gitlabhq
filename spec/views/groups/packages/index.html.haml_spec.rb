# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/packages/index.html.haml', feature_category: :package_registry do
  let_it_be(:group) { build(:group) }

  subject { rendered }

  before do
    assign(:group, group)
  end

  it 'renders vue entrypoint' do
    render

    expect(rendered).to have_selector('#js-vue-packages-list')
  end

  describe 'settings path' do
    it 'without permission sets empty settings path' do
      allow(view).to receive(:show_group_package_registry_settings).and_return(false)

      render

      expect(rendered).to have_selector('[data-settings-path=""]')
    end

    it 'with permission sets group settings path' do
      allow(view).to receive(:show_group_package_registry_settings).and_return(true)

      render

      expect(rendered).to have_selector(
        "[data-settings-path=\"#{group_settings_packages_and_registries_path(group)}\"]"
      )
    end
  end

  describe 'can_delete_packages' do
    it 'without permission sets false' do
      allow(view).to receive(:can_delete_group_packages?).and_return(false)

      render

      expect(rendered).to have_selector('[data-can-delete-packages="false"]')
    end

    it 'with permission sets true' do
      allow(view).to receive(:can_delete_group_packages?).and_return(true)

      render

      expect(rendered).to have_selector('[data-can-delete-packages="true"]')
    end
  end
end
