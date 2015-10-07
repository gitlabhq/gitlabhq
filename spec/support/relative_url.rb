# Fix route helpers in tests (e.g. root_path, ...)
module RelativeUrl
  extend ActiveSupport::Concern

  included do
    default_url_options[:script_name] = Rails.application.config.relative_url_root
  end
end
