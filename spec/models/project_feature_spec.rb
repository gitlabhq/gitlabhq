require 'spec_helper'

describe ProjectFeature do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe '.quoted_access_level_column' do
    it 'returns the table name and quoted column name for a feature' do
      expected = if Gitlab::Database.postgresql?
                   '"project_features"."issues_access_level"'
                 else
                   '`project_features`.`issues_access_level`'
                 end

      expect(described_class.quoted_access_level_column(:issues)).to eq(expected)
    end
  end

  describe '#feature_available?' do
    let(:features) { %w(issues wiki builds merge_requests snippets repository) }

    context 'when features are disabled' do
      it "returns false" do
        features.each do |feature|
          project.project_feature.update_attribute("#{feature}_access_level".to_sym, ProjectFeature::DISABLED)
          expect(project.feature_available?(:issues, user)).to eq(false)
        end
      end
    end

    context 'when features are enabled only for team members' do
      it "returns false when user is not a team member" do
        features.each do |feature|
          project.project_feature.update_attribute("#{feature}_access_level".to_sym, ProjectFeature::PRIVATE)
          expect(project.feature_available?(:issues, user)).to eq(false)
        end
      end

      it "returns true when user is a team member" do
        project.add_developer(user)

        features.each do |feature|
          project.project_feature.update_attribute("#{feature}_access_level".to_sym, ProjectFeature::PRIVATE)
          expect(project.feature_available?(:issues, user)).to eq(true)
        end
      end

      it "returns true when user is a member of project group" do
        group = create(:group)
        project = create(:project, namespace: group)
        group.add_developer(user)

        features.each do |feature|
          project.project_feature.update_attribute("#{feature}_access_level".to_sym, ProjectFeature::PRIVATE)
          expect(project.feature_available?(:issues, user)).to eq(true)
        end
      end

      it "returns true if user is an admin" do
        user.update_attribute(:admin, true)

        features.each do |feature|
          project.project_feature.update_attribute("#{feature}_access_level".to_sym, ProjectFeature::PRIVATE)
          expect(project.feature_available?(:issues, user)).to eq(true)
        end
      end
    end

    context 'when feature is enabled for everyone' do
      it "returns true" do
        features.each do |feature|
          expect(project.feature_available?(:issues, user)).to eq(true)
        end
      end
    end
  end

  context 'repository related features' do
    before do
      project.project_feature.update_attributes(
        merge_requests_access_level: ProjectFeature::DISABLED,
        builds_access_level: ProjectFeature::DISABLED,
        repository_access_level: ProjectFeature::PRIVATE
      )
    end

    it "does not allow repository related features have higher level" do
      features = %w(builds merge_requests)
      project_feature = project.project_feature

      features.each do |feature|
        field = "#{feature}_access_level".to_sym
        project_feature.update_attribute(field, ProjectFeature::ENABLED)
        expect(project_feature.valid?).to be_falsy
      end
    end
  end

  describe '#*_enabled?' do
    let(:features) { %w(wiki builds merge_requests) }

    it "returns false when feature is disabled" do
      features.each do |feature|
        project.project_feature.update_attribute("#{feature}_access_level".to_sym, ProjectFeature::DISABLED)
        expect(project.public_send("#{feature}_enabled?")).to eq(false)
      end
    end

    it "returns true when feature is enabled only for team members" do
      features.each do |feature|
        project.project_feature.update_attribute("#{feature}_access_level".to_sym, ProjectFeature::PRIVATE)
        expect(project.public_send("#{feature}_enabled?")).to eq(true)
      end
    end

    it "returns true when feature is enabled for everyone" do
      features.each do |feature|
        expect(project.public_send("#{feature}_enabled?")).to eq(true)
      end
    end
  end
end
