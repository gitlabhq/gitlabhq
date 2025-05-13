# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Search results for group settings", :js, feature_category: :global_search, type: :feature do
  before do
    stub_config(dependency_proxy: { enabled: true })
  end

  it_behaves_like 'all group settings sections exist and have correct anchor links'
end
