# frozen_string_literal: true

require 'spec_helper'

describe 'admin/application_settings/_repository_storage.html.haml' do
  let(:app_settings) { create(:application_setting) }
  let(:repository_storages_weighted) do
    {
      "mepmep" => 100,
      "foobar" => 50
    }
  end

  before do
    allow(app_settings).to receive(:repository_storages_weighted).and_return(repository_storages_weighted)
    allow(app_settings).to receive(:repository_storages_weighted_mepmep).and_return(100)
    allow(app_settings).to receive(:repository_storages_weighted_foobar).and_return(50)
    assign(:application_setting, app_settings)
  end

  context 'when multiple storages are available' do
    it 'lists them all' do
      render

      repository_storages_weighted.each do |storage_name, storage_weight|
        expect(rendered).to have_content(storage_name)
      end
    end
  end
end
