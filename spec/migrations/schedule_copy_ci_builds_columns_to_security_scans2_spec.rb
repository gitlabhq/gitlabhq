# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleCopyCiBuildsColumnsToSecurityScans2, feature_category: :dependency_scanning do
  it 'is a no-op' do
    migrate!
  end
end
