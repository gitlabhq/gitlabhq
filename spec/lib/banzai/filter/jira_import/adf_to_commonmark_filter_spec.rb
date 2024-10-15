# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::JiraImport::AdfToCommonmarkFilter, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:fixtures_path) { 'lib/kramdown/atlassian_document_format' }

  it 'renders a complex document' do
    source = fixture_file(File.join(fixtures_path, 'complex_document.json'))
    target = fixture_file(File.join(fixtures_path, 'complex_document.md'))

    expect(filter(source)).to eq target
  end

  it 'renders original source when it is invalid JSON' do
    source = fixture_file(File.join(fixtures_path, 'invalid_json.json'))

    expect(filter(source)).to eq "Invalid Atlassian Document Format JSON\n\n#{source}"
  end

  it 'renders original source when missing document node' do
    source = fixture_file(File.join(fixtures_path, 'invalid_no_doc.json'))

    expect(filter(source)).to eq "Invalid Atlassian Document Format JSON\n\n#{source}"
  end
end
