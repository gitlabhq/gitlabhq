# frozen_string_literal: true

require "spec_helper"

RSpec.describe WikiPage, feature_category: :wiki do
  it_behaves_like 'wiki_page', :project
end
