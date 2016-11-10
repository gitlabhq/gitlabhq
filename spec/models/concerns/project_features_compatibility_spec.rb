require 'spec_helper'

describe ProjectFeaturesCompatibility do
  let(:project) { create(:project) }
  let(:features) { %w(issues wiki builds merge_requests snippets) }

  # We had issues_enabled, snippets_enabled, builds_enabled, merge_requests_enabled and issues_enabled fields on projects table
  # All those fields got moved to a new table called project_feature and are now integers instead of booleans
  # This spec tests if the described concern makes sure parameters received by the API are correctly parsed to the new table
  # So we can keep it compatible

  it "converts fields from 'true' to ProjectFeature::ENABLED" do
    features.each do |feature|
      project.update_attribute("#{feature}_enabled".to_sym, "true")
      expect(project.project_feature.public_send("#{feature}_access_level")).to eq(ProjectFeature::ENABLED)
    end
  end

  it "converts fields from 'false' to ProjectFeature::DISABLED" do
    features.each do |feature|
      project.update_attribute("#{feature}_enabled".to_sym, "false")
      expect(project.project_feature.public_send("#{feature}_access_level")).to eq(ProjectFeature::DISABLED)
    end
  end

  it "converts fields from true to ProjectFeature::ENABLED" do
    features.each do |feature|
      project.update_attribute("#{feature}_enabled".to_sym, true)
      expect(project.project_feature.public_send("#{feature}_access_level")).to eq(ProjectFeature::ENABLED)
    end
  end

  it "converts fields from false to ProjectFeature::DISABLED" do
    features.each do |feature|
      project.update_attribute("#{feature}_enabled".to_sym, false)
      expect(project.project_feature.public_send("#{feature}_access_level")).to eq(ProjectFeature::DISABLED)
    end
  end
end
