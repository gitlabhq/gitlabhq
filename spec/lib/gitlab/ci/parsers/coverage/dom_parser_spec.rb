# frozen_string_literal: true

require 'fast_spec_helper'
require 'support/shared_examples/lib/gitlab/ci/parsers/coverage/cobertura_xml_shared_examples'

RSpec.describe Gitlab::Ci::Parsers::Coverage::DomParser do
  subject(:parse_report) { described_class.new.parse(cobertura, coverage_report, project_path, paths) }

  include_examples 'parse cobertura xml'
end
