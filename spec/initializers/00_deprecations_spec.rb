# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '00_deprecations' do
  where(:warning) do
    [
      "ActiveModel::Errors#keys is deprecated and will be removed in Rails 6.2",
      "Rendering actions with '.' in the name is deprecated:",
      "default_hash is deprecated and will be removed from Rails 6.2"
    ]
  end

  with_them do
    specify do
      expect { ActiveSupport::Deprecation.warn(warning) }
        .to raise_error(ActiveSupport::DeprecationException)
    end
  end
end
