# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting merge access levels for a branch protection' do
  it_behaves_like 'a GraphQL query for access levels', :merge
end
