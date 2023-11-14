# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_repository_storage.html.haml' do
  let(:app_settings) { build(:application_setting, repository_storages_weighted: repository_storages_weighted) }

  before do
    stub_storage_settings({ default: {}, mepmep: {}, foobar: {} })
    assign(:application_setting, app_settings)
  end

  context 'with storage weights configured' do
    let(:repository_storages_weighted) do
      {
        'default' => 100,
        'mepmep' => 50,
        'something_old' => 100
      }
    end

    it 'lists storages with weight', :aggregate_failures do
      render

      expect(rendered).to have_field('default', with: 100)
      expect(rendered).to have_field('mepmep', with: 50)
    end

    it 'lists storages without weight' do
      render

      expect(rendered).to have_field('foobar', with: 0)
    end

    it 'lists only configured storages' do
      render

      expect(rendered).not_to have_field('something_old')
    end
  end
end
