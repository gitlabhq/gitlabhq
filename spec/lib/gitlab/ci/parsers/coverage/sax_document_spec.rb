# frozen_string_literal: true

require 'fast_spec_helper'
require 'support/shared_examples/lib/gitlab/ci/parsers/coverage/cobertura_xml_shared_examples'

RSpec.describe Gitlab::Ci::Parsers::Coverage::SaxDocument do
  subject(:parse_report) { Nokogiri::XML::SAX::Parser.new(described_class.new(coverage_report, project_path, paths)).parse(cobertura) }

  include_examples 'parse cobertura xml'
end
