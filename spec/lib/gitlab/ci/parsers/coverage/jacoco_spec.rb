# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Coverage::Jacoco, feature_category: :code_testing do
  let_it_be(:project) { create(:project, :repository) }
  let(:xml_data) { double }
  let(:coverage_report) { double }
  let(:paths) { double }
  let(:merge_request_paths) { double }

  subject(:parse_report) do
    described_class.new.parse!(xml_data,
      coverage_report,
      project: project,
      worktree_paths: paths,
      merge_request_paths: merge_request_paths)
  end

  before do
    allow_next_instance_of(Nokogiri::XML::SAX::Parser) do |document|
      allow(document).to receive(:parse)
    end
  end

  it 'uses Jacoco parser' do
    expect(Gitlab::Ci::Parsers::Coverage::Documents::JacocoDocument).to receive(:new)

    parse_report
  end
end
