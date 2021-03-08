# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectFeaturesCompatibility do
  let(:project) { create(:project) }
  let(:features_enabled) { %w(issues wiki builds merge_requests snippets security_and_compliance) }
  let(:features) { features_enabled + %w(repository pages operations container_registry) }

  # We had issues_enabled, snippets_enabled, builds_enabled, merge_requests_enabled and issues_enabled fields on projects table
  # All those fields got moved to a new table called project_feature and are now integers instead of booleans
  # This spec tests if the described concern makes sure parameters received by the API are correctly parsed to the new table
  # So we can keep it compatible

  it "converts fields from 'true' to ProjectFeature::ENABLED" do
    features_enabled.each do |feature|
      project.update_attribute("#{feature}_enabled".to_sym, "true")
      expect(project.project_feature.public_send("#{feature}_access_level")).to eq(ProjectFeature::ENABLED)
    end
  end

  it "converts fields from 'false' to ProjectFeature::DISABLED" do
    features_enabled.each do |feature|
      project.update_attribute("#{feature}_enabled".to_sym, "false")
      expect(project.project_feature.public_send("#{feature}_access_level")).to eq(ProjectFeature::DISABLED)
    end
  end

  it "converts fields from true to ProjectFeature::ENABLED" do
    features_enabled.each do |feature|
      project.update_attribute("#{feature}_enabled".to_sym, true)
      expect(project.project_feature.public_send("#{feature}_access_level")).to eq(ProjectFeature::ENABLED)
    end
  end

  it "converts fields from false to ProjectFeature::DISABLED" do
    features_enabled.each do |feature|
      project.update_attribute("#{feature}_enabled".to_sym, false)
      expect(project.project_feature.public_send("#{feature}_access_level")).to eq(ProjectFeature::DISABLED)
    end
  end

  describe "access levels" do
    using RSpec::Parameterized::TableSyntax

    where(:access_level, :expected_result) do
      'disabled' | ProjectFeature::DISABLED
      'private'  | ProjectFeature::PRIVATE
      'enabled'  | ProjectFeature::ENABLED
      'public'   | ProjectFeature::PUBLIC
    end

    with_them do
      it "accepts access level" do
        features.each do |feature|
          # Only pages as public access level
          next if feature != 'pages' && access_level == 'public'

          project.update!("#{feature}_access_level".to_sym => access_level)
          expect(project.project_feature.public_send("#{feature}_access_level")).to eq(expected_result)
        end
      end
    end
  end
end
