# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

RSpec.describe Banzai::Pipeline::OrgmodePipeline, feature_category: :markdown do
  it_behaves_like 'sanitize pipeline'
  # OrgmodePipeline receives pre-rendered HTML from org-ruby; pass a bare heading
  # so MarkupHeadingAnchorFilter adds the anchor and HeadingLocalizationFilter localizes it.
  it_behaves_like 'applies heading localization filter',
    heading_input: '<h1>My Heading</h1>',
    heading_text: 'My Heading'
end
