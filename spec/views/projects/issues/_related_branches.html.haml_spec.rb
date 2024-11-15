# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/issues/_related_branches' do
  include Devise::Test::ControllerHelpers

  let(:pipeline) { build(:ci_pipeline, :success) }
  let(:status) { pipeline.detailed_status(build(:user)) }

  before do
    assign(:related_branches,
      [
        { name: 'other', compare_path: 'link-to-other', pipeline_status: nil },
        { name: 'feature', compare_path: 'link-to-feature', pipeline_status: status }

      ]
    )

    render
  end

  it 'shows the related branches with their build status', :aggregate_failures do
    expect(rendered).to have_text('feature')
    expect(rendered).to have_text('other')
    expect(rendered).to have_link(href: 'link-to-feature')
    expect(rendered).to have_link(href: 'link-to-other')
    expect(rendered).to have_css('[data-testid="ci-icon"]')
    expect(rendered).to have_css('.ref-name')
  end
end
