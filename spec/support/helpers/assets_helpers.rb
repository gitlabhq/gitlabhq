# frozen_string_literal: true

module AssetsHelpers
  # In a CI environment the assets are not compiled, as there is a CI job
  # `compile-assets` that compiles them in the prepare stage for all following
  # specs.
  # Locally the assets are precompiled dynamically.
  #
  # Sprockets doesn't provide one method to access an asset for both cases.
  def find_asset(asset_name)
    if ENV['CI']
      Sprockets::Railtie.build_environment(Rails.application, true)[asset_name]
    else
      Rails.application.assets.find_asset(asset_name)
    end
  end
end
