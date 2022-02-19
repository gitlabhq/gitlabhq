# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Coverage::Cobertura do
  let(:xml_data) { double }
  let(:coverage_report) { double }
  let(:project_path) { double }
  let(:paths) { double }

  subject(:parse_report) { described_class.new.parse!(xml_data, coverage_report, project_path: project_path, worktree_paths: paths) }

  context 'when use_cobertura_sax_parser feature flag is enabled' do
    before do
      stub_feature_flags(use_cobertura_sax_parser: true)

      allow_next_instance_of(Nokogiri::XML::SAX::Parser) do |document|
        allow(document).to receive(:parse)
      end
    end

    it 'uses Sax parser' do
      expect(Gitlab::Ci::Parsers::Coverage::SaxDocument).to receive(:new)

      parse_report
    end
  end

  context 'when use_cobertura_sax_parser feature flag is disabled' do
    before do
      stub_feature_flags(use_cobertura_sax_parser: false)

      allow_next_instance_of(Gitlab::Ci::Parsers::Coverage::DomParser) do |parser|
        allow(parser).to receive(:parse)
      end
    end

    it 'uses Dom parser' do
      expect(Gitlab::Ci::Parsers::Coverage::DomParser).to receive(:new)

      parse_report
    end
  end
end
