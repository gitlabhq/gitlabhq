# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Coverage::Cobertura do
  let(:xml_data) { '<coverage></coverage>' }
  let(:coverage_report) { double }
  let(:project_path) { double }
  let(:paths) { double }

  subject(:parse_report) { described_class.new.parse!(xml_data, coverage_report, project_path: project_path, worktree_paths: paths) }

  before do
    allow_next_instance_of(Nokogiri::XML::SAX::Parser) do |document|
      allow(document).to receive(:parse)
    end
  end

  it 'uses Cobertura parser' do
    expect(Gitlab::Ci::Parsers::Coverage::Documents::CoberturaDocument).to receive(:new)

    parse_report
  end

  context 'when the XML data is empty' do
    let(:xml_data) { '' }

    it 'skips parsing' do
      expect(Nokogiri::XML::SAX::Parser).not_to receive(:new)

      expect { parse_report }.not_to raise_error
    end
  end
end
