# frozen_string_literal: true

require 'tempfile'
require 'fileutils'

require_relative '../../../../../tooling/lib/tooling/predictive_tests/test_selector'

RSpec.describe Tooling::PredictiveTests::TestSelector, :aggregate_failures, feature_category: :tooling do
  subject(:test_selector) do
    described_class.new(
      changed_files: changed_files,
      rspec_matching_test_files_path: test_files_path,
      rspec_matching_js_files_path: matching_js_files_path,
      rspec_test_mapping_path: crystalball_mapping_path
    )
  end

  let(:test_files_path) { 'matching_test_files.txt' }
  let(:matching_js_files_path) { 'matching_js_files.txt' }
  let(:views_with_partials_path) { 'views_with_partials.txt' }
  let(:crystalball_mapping_path) { 'crystalball_mapping.txt' }
  let(:rspec_mappings_limit_percentage) { 50 }

  let(:find_tests) { instance_double(Tooling::FindTests, execute: nil) }
  let(:graphql_mappings) { instance_double(Tooling::Mappings::GraphqlBaseTypeMappings, execute: nil) }
  let(:view_to_system_mappings) { instance_double(Tooling::Mappings::ViewToSystemSpecsMappings, execute: nil) }
  let(:view_to_js_mappings) { instance_double(Tooling::Mappings::ViewToJsMappings, execute: nil) }
  let(:js_to_system_mappings) { instance_double(Tooling::Mappings::JsToSystemSpecsMappings, execute: nil) }

  let(:changed_files) { ['app/models/user.rb', 'app/models/todo.rb'] }

  before do
    allow(Tooling::FindTests).to receive(:new).and_return(find_tests)
    allow(Tooling::Mappings::GraphqlBaseTypeMappings).to receive(:new).and_return(graphql_mappings)
    allow(Tooling::Mappings::ViewToSystemSpecsMappings).to receive(:new).and_return(view_to_system_mappings)
    allow(Tooling::Mappings::ViewToJsMappings).to receive(:new).and_return(view_to_js_mappings)
    allow(Tooling::Mappings::JsToSystemSpecsMappings).to receive(:new).and_return(js_to_system_mappings)

    allow(Logger).to receive(:new).and_return(Logger.new(StringIO.new))
  end

  it 'generates predictive rspec test list by calling correct helpers' do
    test_selector.execute

    expect(Tooling::FindTests).to have_received(:new).with(
      changed_files,
      test_files_path,
      mappings_file: crystalball_mapping_path,
      mappings_limit_percentage: rspec_mappings_limit_percentage
    )
    expect(find_tests).to have_received(:execute)

    expect(Tooling::Mappings::GraphqlBaseTypeMappings).to have_received(:new).with(changed_files, test_files_path)
    expect(graphql_mappings).to have_received(:execute)

    expect(Tooling::Mappings::ViewToSystemSpecsMappings).to have_received(:new).with(changed_files, test_files_path)
    expect(view_to_system_mappings).to have_received(:execute)

    expect(Tooling::Mappings::JsToSystemSpecsMappings).to have_received(:new).with(changed_files, test_files_path)
    expect(js_to_system_mappings).to have_received(:execute)
  end

  it 'generates predictive js test list by calling correct helpers' do
    test_selector.execute

    expect(Tooling::Mappings::ViewToJsMappings).to have_received(:new).with(changed_files, matching_js_files_path)
  end
end
