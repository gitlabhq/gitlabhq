# frozen_string_literal: true

require 'spec_helper'

describe VisibilityLevelHelper do
  include ProjectForksHelper

  let(:project)          { build(:project) }
  let(:group)            { build(:group) }
  let(:personal_snippet) { build(:personal_snippet) }
  let(:project_snippet)  { build(:project_snippet) }

  describe 'visibility_icon_description' do
    context 'used with a Project' do
      it 'delegates projects to #project_visibility_icon_description' do
        expect(visibility_icon_description(project))
          .to match /project/i
      end

      context 'used with a ProjectPresenter' do
        it 'delegates projects to #project_visibility_icon_description' do
          expect(visibility_icon_description(project.present))
            .to match /project/i
        end
      end

      context 'used with a Group' do
        it 'delegates groups to #group_visibility_icon_description' do
          expect(visibility_icon_description(group))
            .to match /group/i
        end
      end
    end
  end

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
            .to eq _('Project access must be granted explicitly to each user.')
    end

    it "describes public projects" do
      expect(project_visibility_level_description(Gitlab::VisibilityLevel::PUBLIC))
            .to eq _('The project can be accessed without any authentication.')
    end
  end

  describe "#snippet_visibility_level_description" do
    it 'describes visibility only for me' do
      expect(snippet_visibility_level_description(Gitlab::VisibilityLevel::PRIVATE, personal_snippet))
            .to eq _('The snippet is visible only to me.')
    end

    it 'describes visibility for project members' do
      expect(snippet_visibility_level_description(Gitlab::VisibilityLevel::PRIVATE, project_snippet))
            .to eq _('The snippet is visible only to project members.')
    end

    it 'defaults to personal snippet' do
      expect(snippet_visibility_level_description(Gitlab::VisibilityLevel::PRIVATE))
            .to eq _('The snippet is visible only to me.')
    end
  end

  describe "disallowed_visibility_level?" do
    describe "forks" do
      let(:project) { create(:project, :internal) }
      let(:forked_project) { fork_project(project) }

      it "disallows levels" do
        expect(disallowed_visibility_level?(forked_project, Gitlab::VisibilityLevel::PUBLIC)).to be_truthy
        expect(disallowed_visibility_level?(forked_project, Gitlab::VisibilityLevel::INTERNAL)).to be_falsey
        expect(disallowed_visibility_level?(forked_project, Gitlab::VisibilityLevel::PRIVATE)).to be_falsey
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

  describe "selected_visibility_level" do
    let(:group) { create(:group, :public) }
    let!(:project) { create(:project, :internal, group: group) }
    let!(:forked_project) { fork_project(project) }

    using RSpec::Parameterized::TableSyntax

    PUBLIC = Gitlab::VisibilityLevel::PUBLIC
    INTERNAL = Gitlab::VisibilityLevel::INTERNAL
    PRIVATE = Gitlab::VisibilityLevel::PRIVATE

    # This is a subset of all the permutations
    where(:requested_level, :max_allowed, :global_default_level, :restricted_levels, :expected) do
      PUBLIC | PUBLIC | PUBLIC | [] | PUBLIC
      PUBLIC | PUBLIC | PUBLIC | [PUBLIC] | INTERNAL
      INTERNAL | PUBLIC | PUBLIC | [] | INTERNAL
      INTERNAL | PRIVATE | PRIVATE | [] | PRIVATE
      PRIVATE | PUBLIC | PUBLIC | [] | PRIVATE
      PUBLIC | PRIVATE | INTERNAL | [] | PRIVATE
      PUBLIC | INTERNAL | PUBLIC | [] | INTERNAL
      PUBLIC | PRIVATE | PUBLIC | [] | PRIVATE
      PUBLIC | INTERNAL | INTERNAL | [] | INTERNAL
      PUBLIC | PUBLIC | INTERNAL | [] | PUBLIC
    end

    before do
      stub_application_setting(restricted_visibility_levels: restricted_levels,
                               default_project_visibility: global_default_level)
    end

    with_them do
      it "provides correct visibility level for forked project" do
        project.update(visibility_level: max_allowed)

        expect(selected_visibility_level(forked_project, requested_level)).to eq(expected)
      end

      it "provides correct visibiility level for project in group" do
        project.group.update(visibility_level: max_allowed)

        expect(selected_visibility_level(project, requested_level)).to eq(expected)
      end
    end
  end

  describe 'multiple_visibility_levels_restricted?' do
    using RSpec::Parameterized::TableSyntax

    let(:user) { create(:user) }

    subject { helper.multiple_visibility_levels_restricted? }

    where(:restricted_visibility_levels, :expected) do
      [Gitlab::VisibilityLevel::PUBLIC] | false
      [Gitlab::VisibilityLevel::PUBLIC, Gitlab::VisibilityLevel::INTERNAL] | true
      [Gitlab::VisibilityLevel::PUBLIC, Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PRIVATE] | true
    end

    with_them do
      before do
        allow(helper).to receive(:current_user) { user }
        allow(Gitlab::CurrentSettings.current_application_settings).to receive(:restricted_visibility_levels) { restricted_visibility_levels }
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe 'all_visibility_levels_restricted?' do
    using RSpec::Parameterized::TableSyntax

    let(:user) { create(:user) }

    subject { helper.all_visibility_levels_restricted? }

    where(:restricted_visibility_levels, :expected) do
      [Gitlab::VisibilityLevel::PUBLIC] | false
      [Gitlab::VisibilityLevel::PUBLIC, Gitlab::VisibilityLevel::INTERNAL] | false
      Gitlab::VisibilityLevel.values | true
    end

    with_them do
      before do
        allow(helper).to receive(:current_user) { user }
        allow(Gitlab::CurrentSettings.current_application_settings).to receive(:restricted_visibility_levels) { restricted_visibility_levels }
      end

      it { is_expected.to eq(expected) }
    end
  end
end
