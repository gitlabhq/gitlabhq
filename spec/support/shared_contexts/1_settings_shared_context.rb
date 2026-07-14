# frozen_string_literal: true

RSpec.shared_context 'when loading 1_settings initializer' do
  around do |example|
    original_settings = ::Gitlab::Configs.build_options(Settings.to_hash.deep_dup)

    example.run

    (Settings.keys - original_settings.keys).each { |key| Settings.delete(key) }
    original_settings.each { |key, value| Settings[key] = value }
  end

  def load_settings
    load Rails.root.join('config/initializers/1_settings.rb')
  end
end
