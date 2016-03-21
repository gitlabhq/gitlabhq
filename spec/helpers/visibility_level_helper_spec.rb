require 'spec_helper'

describe VisibilityLevelHelper do
  include Haml::Helpers

  before :all do
    init_haml_helpers
  end

  let(:project)          { build(:project) }
  let(:personal_snippet) { build(:personal_snippet) }
  let(:project_snippet)  { build(:project_snippet) }

  describe 'visibility_level_description' do
    context 'used with a Project' do
      it 'delegates projects to #project_visibility_level_description' do
        expect(visibility_level_description(Gitlab::VisibilityLevel::PRIVATE, project))
            .to match /project/i
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
            .to eq "The project can be cloned without any authentication."
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

  describe "skip_level?" do
    describe "forks" do
      let(:project) { create(:project, :internal) }
      let(:fork_project) { create(:forked_project_with_submodules) }

      before do
        fork_project.build_forked_project_link(forked_to_project_id: fork_project.id, forked_from_project_id: project.id)
        fork_project.save
      end

      it "skips levels" do
        expect(skip_level?(fork_project, Gitlab::VisibilityLevel::PUBLIC)).to be_truthy
        expect(skip_level?(fork_project, Gitlab::VisibilityLevel::INTERNAL)).to be_falsey
        expect(skip_level?(fork_project, Gitlab::VisibilityLevel::PRIVATE)).to be_falsey
      end
    end

    describe "non-forked project" do
      let(:project) { create(:project, :internal) }

      it "skips levels" do
        expect(skip_level?(project, Gitlab::VisibilityLevel::PUBLIC)).to be_falsey
        expect(skip_level?(project, Gitlab::VisibilityLevel::INTERNAL)).to be_falsey
        expect(skip_level?(project, Gitlab::VisibilityLevel::PRIVATE)).to be_falsey
      end
    end

    describe "Snippet" do
      let(:snippet) { create(:snippet, :internal) }

      it "skips levels" do
        expect(skip_level?(snippet, Gitlab::VisibilityLevel::PUBLIC)).to be_falsey
        expect(skip_level?(snippet, Gitlab::VisibilityLevel::INTERNAL)).to be_falsey
        expect(skip_level?(snippet, Gitlab::VisibilityLevel::PRIVATE)).to be_falsey
      end
    end

  end
end
