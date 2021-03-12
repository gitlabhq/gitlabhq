# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VisibilityLevelHelper do
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

  describe 'visibility_level_label' do
    using RSpec::Parameterized::TableSyntax

    where(:level_value, :level_name) do
      Gitlab::VisibilityLevel::PRIVATE | 'Private'
      Gitlab::VisibilityLevel::INTERNAL | 'Internal'
      Gitlab::VisibilityLevel::PUBLIC | 'Public'
    end

    with_them do
      it 'returns the name of the visibility level' do
        expect(visibility_level_label(level_value)).to eq(level_name)
      end
    end
  end

  describe 'visibility_level_description' do
    context 'used with a Project' do
      let(:descriptions) do
        [
          visibility_level_description(Gitlab::VisibilityLevel::PRIVATE, project),
          visibility_level_description(Gitlab::VisibilityLevel::INTERNAL, project),
          visibility_level_description(Gitlab::VisibilityLevel::PUBLIC, project)
        ]
      end

      it 'returns different project related descriptions depending on visibility level' do
        expect(descriptions.uniq.size).to eq(descriptions.size)
        expect(descriptions).to all match /project/i
      end
    end

    context 'used with a Group' do
      let(:descriptions) do
        [
          visibility_level_description(Gitlab::VisibilityLevel::PRIVATE, group),
          visibility_level_description(Gitlab::VisibilityLevel::INTERNAL, group),
          visibility_level_description(Gitlab::VisibilityLevel::PUBLIC, group)
        ]
      end

      it 'returns different group related descriptions depending on visibility level' do
        expect(descriptions.uniq.size).to eq(descriptions.size)
        expect(descriptions).to all match /group/i
      end
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

    public_vis = Gitlab::VisibilityLevel::PUBLIC
    internal_vis = Gitlab::VisibilityLevel::INTERNAL
    private_vis = Gitlab::VisibilityLevel::PRIVATE

    # This is a subset of all the permutations
    where(:requested_level, :max_allowed, :global_default_level, :restricted_levels, :expected) do
      public_vis | public_vis | public_vis | [] | public_vis
      public_vis | public_vis | public_vis | [public_vis] | internal_vis
      internal_vis | public_vis | public_vis | [] | internal_vis
      internal_vis | private_vis | private_vis | [] | private_vis
      private_vis | public_vis | public_vis | [] | private_vis
      public_vis | private_vis | internal_vis | [] | private_vis
      public_vis | internal_vis | public_vis | [] | internal_vis
      public_vis | private_vis | public_vis | [] | private_vis
      public_vis | internal_vis | internal_vis | [] | internal_vis
      public_vis | public_vis | internal_vis | [] | public_vis
    end

    before do
      stub_application_setting(restricted_visibility_levels: restricted_levels,
                               default_project_visibility: global_default_level)
    end

    with_them do
      it "provides correct visibility level for forked project" do
        project.update!(visibility_level: max_allowed)

        expect(selected_visibility_level(forked_project, requested_level)).to eq(expected)
      end

      it "provides correct visibility level for project in group" do
        project.update!(visibility_level: max_allowed)
        project.group.update!(visibility_level: max_allowed)

        expect(selected_visibility_level(project, requested_level)).to eq(expected)
      end
    end
  end

  shared_examples_for 'available visibility level' do
    using RSpec::Parameterized::TableSyntax

    let(:user) { create(:user) }

    subject { helper.available_visibility_levels(form_model) }

    public_vis = Gitlab::VisibilityLevel::PUBLIC
    internal_vis = Gitlab::VisibilityLevel::INTERNAL
    private_vis = Gitlab::VisibilityLevel::PRIVATE

    where(:restricted_visibility_levels, :expected) do
      [] | [private_vis, internal_vis, public_vis]
      [private_vis] | [internal_vis, public_vis]
      [private_vis, internal_vis] | [public_vis]
      [private_vis, public_vis] | [internal_vis]
      [internal_vis] | [private_vis, public_vis]
      [internal_vis, private_vis] | [public_vis]
      [internal_vis, public_vis] | [private_vis]
      [public_vis] | [private_vis, internal_vis]
      [public_vis, private_vis] | [internal_vis]
      [public_vis, internal_vis] | [private_vis]
    end

    before do
      allow(helper).to receive(:current_user) { user }
    end

    with_them do
      before do
        stub_application_setting(restricted_visibility_levels: restricted_visibility_levels)
      end

      it { is_expected.to eq(expected) }
    end

    it 'excludes disallowed visibility levels' do
      stub_application_setting(restricted_visibility_levels: [])
      allow(helper).to receive(:disallowed_visibility_level?).with(form_model, private_vis) { true }
      allow(helper).to receive(:disallowed_visibility_level?).with(form_model, internal_vis) { false }
      allow(helper).to receive(:disallowed_visibility_level?).with(form_model, public_vis) { false }

      expect(subject).to eq([internal_vis, public_vis])
    end
  end

  describe '#available_visibility_levels' do
    it_behaves_like 'available visibility level' do
      let(:form_model) { project_snippet }
    end

    it_behaves_like 'available visibility level' do
      let(:form_model) { personal_snippet }
    end

    it_behaves_like 'available visibility level' do
      let(:form_model) { project }
    end

    it_behaves_like 'available visibility level' do
      let(:form_model) { group }
    end
  end

  describe '#snippets_selected_visibility_level' do
    let(:available_levels) { [Gitlab::VisibilityLevel::PUBLIC, Gitlab::VisibilityLevel::INTERNAL] }

    it 'returns the selected visibility level' do
      expect(helper.snippets_selected_visibility_level(available_levels, Gitlab::VisibilityLevel::PUBLIC))
        .to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    it "fallbacks using the lowest available visibility level when selected level isn't available" do
      expect(helper.snippets_selected_visibility_level(available_levels, Gitlab::VisibilityLevel::PRIVATE))
       .to eq(Gitlab::VisibilityLevel::INTERNAL)
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

  describe '#visibility_level_options' do
    let(:user) { build(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'returns the desired mapping' do
      expected_options = [
        {
          level: 0,
          label: 'Private',
          description: 'The group and its projects can only be viewed by members.'
        },
        {
          level: 10,
          label: 'Internal',
          description: 'The group and any internal projects can be viewed by any logged in user except external users.'
        },
        {
          level: 20,
          label: 'Public',
          description: 'The group and any public projects can be viewed without any authentication.'
        }
      ]

      expect(helper.visibility_level_options(group)).to eq expected_options
    end
  end
end
