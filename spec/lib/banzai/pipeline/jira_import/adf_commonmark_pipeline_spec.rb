# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::JiraImport::AdfCommonmarkPipeline, feature_category: :markdown do
  let_it_be(:fixtures_path) { 'lib/kramdown/atlassian_document_format' }

  it 'converts text in Atlassian Document Format' do
    source = fixture_file(File.join(fixtures_path, 'paragraph.json'))
    target = fixture_file(File.join(fixtures_path, 'paragraph.md'))
    output = described_class.call(source, {})[:output]

    expect(output).to eq target
  end
end
