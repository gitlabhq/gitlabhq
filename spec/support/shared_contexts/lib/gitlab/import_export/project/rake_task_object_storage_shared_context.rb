# frozen_string_literal: true

RSpec.shared_context 'rake task object storage shared context' do
  before do
    allow(Settings.uploads.object_store).to receive(:[]=).and_call_original
  end

  around do |example|
    old_object_store_setting = Settings.uploads.object_store['enabled']

    Settings.uploads.object_store['enabled'] = true

    example.run

    Settings.uploads.object_store['enabled'] = old_object_store_setting
  end
end
