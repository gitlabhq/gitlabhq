# frozen_string_literal: true

require_relative '../../../../../tooling/lib/tooling/predictive_tests/changed_files'

RSpec.describe Tooling::PredictiveTests::ChangedFiles, :aggregate_failures, feature_category: :tooling do
  subject(:changed_files) { described_class }

  let(:base_changes) { ['app/models/user.rb', 'app/models/todo.rb'] }
  let(:ff_files) { ['app/features/dummy_feature_2.rb'] }
  let(:views) { ['app/views/todos/show.html.haml', 'app/views/todos/_todo.haml'] }
  let(:js_files) { ['related_to_view.js'] }

  let(:find_files_using_feature_flags) { instance_double(Tooling::FindFilesUsingFeatureFlags, execute: ff_files) }
  let(:partial_to_views_mappings) { instance_double(Tooling::Mappings::PartialToViewsMappings, execute: views) }
  let(:view_to_js_mappings) { instance_double(Tooling::Mappings::ViewToJsMappings, execute: js_files) }

  before do
    allow(Tooling::FindFilesUsingFeatureFlags).to receive(:new).and_return(find_files_using_feature_flags)
    allow(Tooling::Mappings::PartialToViewsMappings).to receive(:new).and_return(partial_to_views_mappings)
    allow(Tooling::Mappings::ViewToJsMappings).to receive(:new).and_return(view_to_js_mappings)
  end

  it "returns feature flag and view related changes" do
    expect(changed_files.fetch(changes: base_changes)).to match_array(base_changes + ff_files + views + js_files)

    expect(Tooling::FindFilesUsingFeatureFlags).to have_received(:new).with(changed_files: base_changes).once
    expect(Tooling::Mappings::PartialToViewsMappings).to have_received(:new).with(base_changes).once
    expect(Tooling::Mappings::ViewToJsMappings).to have_received(:new).with(base_changes + views).once
  end

  it "skips feature flag related file fetching" do
    expect(changed_files.fetch(changes: base_changes, with_ff_related_files: false)).to match_array(
      base_changes + views + js_files
    )

    expect(Tooling::Mappings::PartialToViewsMappings).to have_received(:new).with(base_changes)
    expect(Tooling::Mappings::ViewToJsMappings).to have_received(:new).with(base_changes + views).once
    expect(Tooling::FindFilesUsingFeatureFlags).not_to have_received(:new)
  end

  it "skips view file fetching" do
    expect(changed_files.fetch(changes: base_changes, with_views: false)).to match_array(
      base_changes + ff_files + js_files
    )

    expect(Tooling::FindFilesUsingFeatureFlags).to have_received(:new).with(changed_files: base_changes).once
    expect(Tooling::Mappings::ViewToJsMappings).to have_received(:new).with(base_changes).once
    expect(Tooling::Mappings::PartialToViewsMappings).not_to have_received(:new)
  end

  it "skips related js files" do
    expect(changed_files.fetch(changes: base_changes, with_js_files: false)).to match_array(
      base_changes + ff_files + views
    )

    expect(Tooling::FindFilesUsingFeatureFlags).to have_received(:new).with(changed_files: base_changes).once
    expect(Tooling::Mappings::PartialToViewsMappings).to have_received(:new).with(base_changes).once
    expect(Tooling::Mappings::ViewToJsMappings).not_to have_received(:new)
  end

  context "with duplicate files" do
    let(:ff_files) { ['app/models/user.rb'] }

    it "returns only unique files" do
      expect(changed_files.fetch(changes: base_changes)).to match_array(base_changes + views + js_files)
    end
  end
end
