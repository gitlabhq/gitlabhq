require 'spec_helper'

describe VisibilityLevelHelper do
  let(:project)          { build(:project) }
  let(:group)            { build(:group) }
  let(:personal_snippet) { build(:personal_snippet) }
  let(:project_snippet)  { build(:project_snippet) }

  describe 'visibility_level_description' do
    context 'used with a Project' do
      it 'delegates projects to #project_visibility_level_description' do
        expect(visibility_level_description(Gitlab::VisibilityLevel::PRIVATE, project))
            .to match /project/i
      end
    end

    context 'used with a Group' do
      it 'delegates groups to #group_visibility_level_description' do
        expect(visibility_level_description(Gitlab::VisibilityLevel::PRIVATE, group))
            .to match /group/i
      end
    end

    context 'called with a Snippet' do
      it 'delegates snippets to #snippet_visibility_level_description' do
        expect(visibility_level_description(Gitlab::VisibilityLevel::INTERNAL, project_snippet))
            .to match /snippet/i
      end
    end
  end

  describe "#project_visibility_level_description" do
    it "describes private projects" do
      expect(project_visibility_level_description(Gitlab::VisibilityLevel::PRIVATE))
            .to eq "Project access must be granted explicitly to each user."
    end

    it "describes public projects" do
      expect(project_visibility_level_description(Gitlab::VisibilityLevel::PUBLIC))
            .to eq "The project can be accessed without any authentication."
    end
  end

  describe "#snippet_visibility_level_description" do
    it 'describes visibility only for me' do
      expect(snippet_visibility_level_description(Gitlab::VisibilityLevel::PRIVATE, personal_snippet))
            .to eq "The snippet is visible only to me."
    end

    it 'describes visibility for project members' do
      expect(snippet_visibility_level_description(Gitlab::VisibilityLevel::PRIVATE, project_snippet))
            .to eq "The snippet is visible only to project members."
    end

    it 'defaults to personal snippet' do
      expect(snippet_visibility_level_description(Gitlab::VisibilityLevel::PRIVATE))
            .to eq "The snippet is visible only to me."
    end
  end

  describe "disallowed_visibility_level?" do
    describe "forks" do
      let(:project)       { create(:project, :internal) }
      let(:fork_project)  { create(:project, forked_from_project: project) }

      it "disallows levels" do
        expect(disallowed_visibility_level?(fork_project, Gitlab::VisibilityLevel::PUBLIC)).to be_truthy
        expect(disallowed_visibility_level?(fork_project, Gitlab::VisibilityLevel::INTERNAL)).to be_falsey
        expect(disallowed_visibility_level?(fork_project, Gitlab::VisibilityLevel::PRIVATE)).to be_falsey
      end
    end

    describe "non-forked project" do
      let(:project) { create(:project, :internal) }

      it "disallows levels" do
        expect(disallowed_visibility_level?(project, Gitlab::VisibilityLevel::PUBLIC)).to be_falsey
        expect(disallowed_visibility_level?(project, Gitlab::VisibilityLevel::INTERNAL)).to be_falsey
        expect(disallowed_visibility_level?(project, Gitlab::VisibilityLevel::PRIVATE)).to be_falsey
      end
    end

    describe "group" do
      let(:group) { create(:group, :internal) }

      it "disallows levels" do
        expect(disallowed_visibility_level?(group, Gitlab::VisibilityLevel::PUBLIC)).to be_falsey
        expect(disallowed_visibility_level?(group, Gitlab::VisibilityLevel::INTERNAL)).to be_falsey
        expect(disallowed_visibility_level?(group, Gitlab::VisibilityLevel::PRIVATE)).to be_falsey
      end
    end

    describe "sub-group" do
      let(:group) { create(:group, :private) }
      let(:subgroup) { create(:group, :private, parent: group) }

      it "disallows levels" do
        expect(disallowed_visibility_level?(subgroup, Gitlab::VisibilityLevel::PUBLIC)).to be_truthy
        expect(disallowed_visibility_level?(subgroup, Gitlab::VisibilityLevel::INTERNAL)).to be_truthy
        expect(disallowed_visibility_level?(subgroup, Gitlab::VisibilityLevel::PRIVATE)).to be_falsey
      end
    end

    describe "snippet" do
      let(:snippet) { create(:snippet, :internal) }

      it "disallows levels" do
        expect(disallowed_visibility_level?(snippet, Gitlab::VisibilityLevel::PUBLIC)).to be_falsey
        expect(disallowed_visibility_level?(snippet, Gitlab::VisibilityLevel::INTERNAL)).to be_falsey
        expect(disallowed_visibility_level?(snippet, Gitlab::VisibilityLevel::PRIVATE)).to be_falsey
      end
    end
  end

  describe "disallowed_visibility_level_description" do
    let(:group) { create(:group, :internal) }
    let!(:subgroup) { create(:group, :internal, parent: group) }
    let!(:project) { create(:project, :internal, group: group) }

    describe "project" do
      it "provides correct description for disabled levels" do
        expect(disallowed_visibility_level?(project, Gitlab::VisibilityLevel::PUBLIC)).to be_truthy
        expect(strip_tags disallowed_visibility_level_description(Gitlab::VisibilityLevel::PUBLIC, project))
          .to include "the visibility of #{project.group.name} is internal"
      end
    end

    describe "group" do
      it "provides correct description for disabled levels" do
        expect(disallowed_visibility_level?(group, Gitlab::VisibilityLevel::PRIVATE)).to be_truthy
        expect(disallowed_visibility_level_description(Gitlab::VisibilityLevel::PRIVATE, group))
          .to include "it contains projects with higher visibility", "it contains sub-groups with higher visibility"

        expect(disallowed_visibility_level?(subgroup, Gitlab::VisibilityLevel::PUBLIC)).to be_truthy
        expect(strip_tags disallowed_visibility_level_description(Gitlab::VisibilityLevel::PUBLIC, subgroup))
          .to include "the visibility of #{group.name} is internal"
      end
    end
  end
end
