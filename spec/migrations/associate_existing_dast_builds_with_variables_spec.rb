# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AssociateExistingDastBuildsWithVariables do
  it 'is a no-op' do
    migrate!
  end
end
