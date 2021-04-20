# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Featurable do
  let_it_be(:user) { create(:user) }

  let(:project) { create(:project) }
  let(:feature_class) { subject.class }
  let(:features) { feature_class::FEATURES }

  subject { project.project_feature }

  describe '.quoted_access_level_column' do
    it 'returns the table name and quoted column name for a feature' do
      expected = '"project_features"."issues_access_level"'

      expect(feature_class.quoted_access_level_column(:issues)).to eq(expected)
    end
  end

  describe '.access_level_attribute' do
    it { expect(feature_class.access_level_attribute(:wiki)).to eq :wiki_access_level }

    it 'raises error for unspecified feature' do
      expect { feature_class.access_level_attribute(:unknown) }
        .to raise_error(ArgumentError, /invalid feature: unknown/)
    end
  end

  describe '.set_available_features' do
    let!(:klass) do
      Class.new do
        include Featurable
        set_available_features %i(feature1 feature2)

        def feature1_access_level
          Featurable::DISABLED
        end

        def feature2_access_level
          Featurable::ENABLED
        end
      end
    end

    let!(:instance) { klass.new }

    it { expect(klass.available_features).to eq [:feature1, :feature2] }
    it { expect(instance.feature1_enabled?).to be_falsey }
    it { expect(instance.feature2_enabled?).to be_truthy }
  end

  describe '.available_features' do
    it { expect(feature_class.available_features).to include(*features) }
  end

  describe '#access_level' do
    it 'returns access level' do
      expect(subject.access_level(:wiki)).to eq(subject.wiki_access_level)
    end
  end

  describe '#feature_available?' do
    let(:features) { %w(issues wiki builds merge_requests snippets repository pages metrics_dashboard) }

    context 'when features are disabled' do
      it "returns false" do
        update_all_project_features(project, features, ProjectFeature::DISABLED)

        features.each do |feature|
          expect(project.feature_available?(feature.to_sym, user)).to eq(false), "#{feature} failed"
        end
      end
    end

    context 'when features are enabled only for team members' do
      it "returns false when user is not a team member" do
        update_all_project_features(project, features, ProjectFeature::PRIVATE)

        features.each do |feature|
          expect(project.feature_available?(feature.to_sym, user)).to eq(false), "#{feature} failed"
        end
      end

      it "returns true when user is a team member" do
        project.add_developer(user)

        update_all_project_features(project, features, ProjectFeature::PRIVATE)

        features.each do |feature|
          expect(project.feature_available?(feature.to_sym, user)).to eq(true), "#{feature} failed"
        end
      end

      it "returns true when user is a member of project group" do
        group = create(:group)
        project = create(:project, namespace: group)
        group.add_developer(user)

        update_all_project_features(project, features, ProjectFeature::PRIVATE)

        features.each do |feature|
          expect(project.feature_available?(feature.to_sym, user)).to eq(true), "#{feature} failed"
        end
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it "returns true if user is an admin" do
          user.update_attribute(:admin, true)

          update_all_project_features(project, features, ProjectFeature::PRIVATE)

          features.each do |feature|
            expect(project.feature_available?(feature.to_sym, user)).to eq(true), "#{feature} failed"
          end
        end
      end

      context 'when admin mode is disabled' do
        it "returns false when user is an admin" do
          user.update_attribute(:admin, true)

          update_all_project_features(project, features, ProjectFeature::PRIVATE)

          features.each do |feature|
            expect(project.feature_available?(feature.to_sym, user)).to eq(false), "#{feature} failed"
          end
        end
      end
    end

    context 'when feature is enabled for everyone' do
      it "returns true" do
        expect(project.feature_available?(:issues, user)).to eq(true)
      end
    end
  end

  describe '#*_enabled?' do
    let(:features) { %w(wiki builds merge_requests) }

    it "returns false when feature is disabled" do
      update_all_project_features(project, features, ProjectFeature::DISABLED)

      features.each do |feature|
        expect(project.public_send("#{feature}_enabled?")).to eq(false), "#{feature} failed"
      end
    end

    it "returns true when feature is enabled only for team members" do
      update_all_project_features(project, features, ProjectFeature::PRIVATE)

      features.each do |feature|
        expect(project.public_send("#{feature}_enabled?")).to eq(true), "#{feature} failed"
      end
    end

    it "returns true when feature is enabled for everyone" do
      features.each do |feature|
        expect(project.public_send("#{feature}_enabled?")).to eq(true), "#{feature} failed"
      end
    end
  end

  def update_all_project_features(project, features, value)
    project_feature_attributes = features.to_h { |f| ["#{f}_access_level", value] }
    project.project_feature.update!(project_feature_attributes)
  end
end
