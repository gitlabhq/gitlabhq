# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'searching groups', :with_license, feature_category: :groups_and_projects do
  it_behaves_like 'groups query'
end
