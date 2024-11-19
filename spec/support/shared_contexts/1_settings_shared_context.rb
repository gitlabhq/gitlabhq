# frozen_string_literal: true

RSpec.shared_context 'when loading 1_settings initializer' do
  def load_settings
    # Avoid wrapping Gitlab::Pages::Settings again
    Settings.pages = Settings.pages.__getobj__

    load Rails.root.join('config/initializers/1_settings.rb')
  end
end
