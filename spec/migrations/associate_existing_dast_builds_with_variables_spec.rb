# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AssociateExistingDastBuildsWithVariables, feature_category: :dynamic_application_security_testing do
  it 'is a no-op' do
    migrate!
  end
end
