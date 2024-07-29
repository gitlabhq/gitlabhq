# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Search results for project settings", :js, feature_category: :global_search, type: :feature do
  it_behaves_like 'all project settings sections exist and have correct anchor links'
end
