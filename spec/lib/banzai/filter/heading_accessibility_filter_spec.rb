# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::HeadingAccessibilityFilter, feature_category: :markdown do
  include FilterSpecHelper

  def filter(markdown)
    Banzai::PipelineBase.new([Banzai::Filter::MarkdownFilter, described_class]).call(markdown)[:output]
  end

  def pipeline_filter(text, context = {})
    context = { project: nil, no_sourcepos: true }.merge(context)

    doc = Banzai::Pipeline::PreProcessPipeline.call(text, {})
    doc = Banzai::Pipeline::FullPipeline.call(doc[:output], context)

    doc[:output]
  end

  it 'rewrites heading aria-labels' do
    expect_next_instance_of(described_class) do |instance|
      expect(instance).to receive(:_).and_return("Link pealkirjale '%{heading}'")
    end
    doc = filter("# Tere, maailm!")
    a = doc.css('h1 > a.anchor').first
    expect(a['aria-label']).to eq("Link pealkirjale 'Tere, maailm!'")
  end

  # Check that (a) it actually runs, and (b) the needed attributes aren't sanitised out.
  it 'rewrites heading aria-labels in the full pipeline' do
    expect_next_instance_of(described_class) do |instance|
      expect(instance).to receive(:_).and_return("Link pealkirjale '%{heading}'")
    end
    doc = pipeline_filter("# Tere, maailm!")
    a = doc.css('h1 > a.anchor').first
    expect(a['aria-label']).to eq("Link pealkirjale 'Tere, maailm!'")
  end
end
