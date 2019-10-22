# frozen_string_literal: true

require 'spec_helper'

describe 'admin/application_settings/_repository_storage.html.haml' do
  let(:app_settings) { build(:application_setting) }
  let(:storages) do
    {
      "mepmep" => { "path" => "/tmp" },
      "foobar" => { "path" => "/tmp" }
    }
  end

  before do
    assign(:application_setting, app_settings)
    stub_storage_settings(storages)
  end

  context 'when multiple storages are available' do
    it 'lists them all' do
      render

      storages.keys.each do |storage_name|
        expect(rendered).to have_content(storage_name)
      end
    end
  end
end
