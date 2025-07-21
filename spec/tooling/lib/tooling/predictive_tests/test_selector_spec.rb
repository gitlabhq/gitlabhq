# frozen_string_literal: true

require_relative "../../../../../tooling/lib/tooling/predictive_tests/test_selector"

RSpec.describe Tooling::PredictiveTests::TestSelector, :aggregate_failures, feature_category: :tooling do
  subject(:test_selector) do
    described_class.new(changed_files: changed_files, rspec_test_mapping_path: crystalball_mapping_path)
  end

  let(:crystalball_mapping_path) { "crystalball_mapping.txt" }
  let(:changed_files) { ["app/models/user.rb", "app/models/todo.rb"] }
  let(:rspec_mappings_limit_percentage) { 50 }

  let(:find_tests) { instance_double(Tooling::FindTests, execute: ["specs_from_mapping"]) }

  let(:graphql_mappings) do
    instance_double(Tooling::Mappings::GraphqlBaseTypeMappings, execute: ["specs_from_graphql"])
  end

  let(:view_to_system_mappings) do
    instance_double(Tooling::Mappings::ViewToSystemSpecsMappings, execute: ["specs_from_views"])
  end

  let(:js_to_system_mappings) do
    instance_double(Tooling::Mappings::JsToSystemSpecsMappings, execute: ["specs_from_js"])
  end

  before do
    allow(Tooling::FindTests).to receive(:new).and_return(find_tests)
    allow(Tooling::Mappings::GraphqlBaseTypeMappings).to receive(:new).and_return(graphql_mappings)
    allow(Tooling::Mappings::ViewToSystemSpecsMappings).to receive(:new).and_return(view_to_system_mappings)
    allow(Tooling::Mappings::JsToSystemSpecsMappings).to receive(:new).and_return(js_to_system_mappings)

    allow(Logger).to receive(:new).and_return(Logger.new(StringIO.new))
  end

  it "generates predictive rspec test list" do
    expect(test_selector.rspec_spec_list).to match_array(%w[
      specs_from_graphql
      specs_from_views
      specs_from_js
      specs_from_mapping
    ])

    expect(Tooling::Mappings::GraphqlBaseTypeMappings).to have_received(:new).with(changed_files)
    expect(Tooling::Mappings::ViewToSystemSpecsMappings).to have_received(:new).with(changed_files)
    expect(Tooling::Mappings::JsToSystemSpecsMappings).to have_received(:new).with(changed_files)
    expect(Tooling::FindTests).to have_received(:new).with(
      changed_files,
      mappings_file: crystalball_mapping_path,
      mappings_limit_percentage: rspec_mappings_limit_percentage
    )
  end
end
