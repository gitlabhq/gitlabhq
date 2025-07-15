# frozen_string_literal: true

require_relative '../../../../../tooling/lib/tooling/predictive_tests/changed_files'

RSpec.describe Tooling::PredictiveTests::ChangedFiles, :aggregate_failures, feature_category: :tooling do
  subject(:changed_files) { described_class }

  let(:mr_changes) { ['app/models/user.rb', 'app/models/todo.rb'] }
  let(:ff_files) { ['app/features/dummy_feature_2.rb'] }
  let(:views) { ['app/views/todos/show.html.haml', 'app/views/todos/_todo.haml'] }

  let(:find_changes) { instance_double(Tooling::FindChanges, execute: mr_changes) }
  let(:find_files_using_feature_flags) { instance_double(Tooling::FindFilesUsingFeatureFlags, execute: ff_files) }
  let(:partial_to_views_mappings) { instance_double(Tooling::Mappings::PartialToViewsMappings, execute: views) }

  before do
    allow(Tooling::FindChanges).to receive(:new).and_return(find_changes)
    allow(Tooling::FindFilesUsingFeatureFlags).to receive(:new).and_return(find_files_using_feature_flags)
    allow(Tooling::Mappings::PartialToViewsMappings).to receive(:new).and_return(partial_to_views_mappings)
  end

  it "returns changes and related files by default" do
    expect(Tooling::FindChanges).to receive(:new).with(from: :api, frontend_fixtures_mapping_pathname: nil).once
    expect(Tooling::FindFilesUsingFeatureFlags).to receive(:new).with(changed_files: mr_changes).once
    expect(Tooling::Mappings::PartialToViewsMappings).to receive(:new).with([*mr_changes, *ff_files]).once

    expect(changed_files.fetch).to match_array([*mr_changes, *ff_files, *views])
  end

  it "skips feature flag related file fetching" do
    expect(Tooling::FindChanges).to receive(:new).with(from: :api, frontend_fixtures_mapping_pathname: nil)
    expect(Tooling::Mappings::PartialToViewsMappings).to receive(:new).with(mr_changes)
    expect(Tooling::FindFilesUsingFeatureFlags).not_to receive(:new)

    expect(changed_files.fetch(with_ff_related_files: false)).to match_array([*mr_changes, *views])
  end

  it "skips view file fetching" do
    expect(Tooling::FindChanges).to receive(:new).with(from: :api, frontend_fixtures_mapping_pathname: nil)
    expect(Tooling::FindFilesUsingFeatureFlags).to receive(:new).with(changed_files: mr_changes).once
    expect(Tooling::Mappings::PartialToViewsMappings).not_to receive(:new)

    expect(changed_files.fetch(with_views: false)).to match_array([*mr_changes, *ff_files])
  end

  context "with duplicate files" do
    let(:ff_files) { ['app/models/user.rb'] }

    it "returns only unique files" do
      expect(changed_files.fetch).to match_array([*mr_changes, *views])
    end
  end

  context "with frontend fixtures" do
    it "uses frontend fixtures mapping file when provided" do
      changed_files.fetch(frontend_fixtures_file: "path/to/frontend_fixtures_mapping.txt")

      expect(Tooling::FindChanges).to have_received(:new).with(
        from: :api,
        frontend_fixtures_mapping_pathname: "path/to/frontend_fixtures_mapping.txt"
      )
    end
  end
end
