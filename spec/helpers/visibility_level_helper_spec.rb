# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VisibilityLevelHelper, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  include ProjectForksHelper

  public_vis = Gitlab::VisibilityLevel::PUBLIC
  internal_vis = Gitlab::VisibilityLevel::INTERNAL
  private_vis = Gitlab::VisibilityLevel::PRIVATE

  let(:project)          { build(:project) }
  let(:group)            { build(:group) }
  let(:personal_snippet) { build(:personal_snippet) }
  let(:project_snippet)  { build(:project_snippet) }

  describe '#visibility_icon_description' do
    context 'with Project' do
      it 'delegates projects to #project_visibility_icon_description' do
        expect(visibility_icon_description(project)).to match(/project/i)
      end
    end

    context 'with ProjectPresenter' do
      it 'delegates projects to #project_visibility_icon_description' do
        expect(visibility_icon_description(project.present)).to match(/project/i)
      end
    end

    context 'with Group' do
      it 'delegates groups to #group_visibility_icon_description' do
        expect(visibility_icon_description(group)).to match(/group/i)
      end
    end
  end

  describe '#visibility_level_label' do
    where(:level_value, :level_name) do
      private_vis  | 'Private'
      internal_vis | 'Internal'
      public_vis   | 'Public'
    end

    with_them do
      subject { visibility_level_label(level_value) }

      it { is_expected.to eq(level_name) }
    end
  end

  describe '#visibility_level_description' do
    context 'with Project' do
      let(:descriptions) do
        [
          visibility_level_description(private_vis, project),
          visibility_level_description(internal_vis, project),
          visibility_level_description(public_vis, project)
        ]
      end

      it 'returns different project related descriptions depending on visibility level' do
        expect(descriptions.uniq.size).to eq(descriptions.size)
        expect(descriptions).to all match(/project/i)
      end
    end

    context 'with Group' do
      let(:descriptions) do
        [
          visibility_level_description(private_vis, group),
          visibility_level_description(internal_vis, group),
          visibility_level_description(public_vis, group)
        ]
      end

      it 'returns different group related descriptions depending on visibility level' do
        expect(descriptions.uniq.size).to eq(descriptions.size)
        expect(descriptions).to all match(/group/i)
      end

      it 'returns default description for public group' do
        expect(descriptions[2]).to eq('The group and any public projects can be viewed without any authentication.')
      end

      context 'when application setting `should_check_namespace_plan` is true', if: Gitlab.ee? do
        let(:group) { build_stubbed(:group) }
        let(:public_option_description) { visibility_level_description(public_vis, group) }

        before do
          allow(Gitlab::CurrentSettings.current_application_settings).to receive(:should_check_namespace_plan?)
                                                                     .and_return(true)
        end

        it 'returns updated description for public visibility option in group general settings' do
          expect(public_option_description).to match(
            'The group, any public projects, and any of their members, issues, and merge requests can be viewed ' \
              'without authentication.'
          )
        end
      end
    end
  end

  describe '#disallowed_visibility_level?' do
    describe "forks" do
      let(:project) { create(:project, :internal) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- create is required for fork_project
      let(:forked_project) { fork_project(project) }

      it "disallows levels" do
        expect(disallowed_visibility_level?(forked_project, public_vis)).to be_truthy
        expect(disallowed_visibility_level?(forked_project, internal_vis)).to be_falsey
        expect(disallowed_visibility_level?(forked_project, private_vis)).to be_falsey
      end
    end

    describe "non-forked project" do
      let(:project) { build_stubbed(:project, :internal) }

      it "disallows levels" do
        expect(disallowed_visibility_level?(project, public_vis)).to be_falsey
        expect(disallowed_visibility_level?(project, internal_vis)).to be_falsey
        expect(disallowed_visibility_level?(project, private_vis)).to be_falsey
      end
    end

    describe "group" do
      let(:group) { build_stubbed(:group, :internal) }

      it "disallows levels" do
        expect(disallowed_visibility_level?(group, public_vis)).to be_falsey
        expect(disallowed_visibility_level?(group, internal_vis)).to be_falsey
        expect(disallowed_visibility_level?(group, private_vis)).to be_falsey
      end
    end

    describe "sub-group" do
      let(:group) { build_stubbed(:group, :private) }
      let(:subgroup) { build_stubbed(:group, :private, parent: group) }

      it "disallows levels" do
        expect(disallowed_visibility_level?(subgroup, public_vis)).to be_truthy
        expect(disallowed_visibility_level?(subgroup, internal_vis)).to be_truthy
        expect(disallowed_visibility_level?(subgroup, private_vis)).to be_falsey
      end
    end

    describe "snippet" do
      let(:snippet) { build_stubbed(:personal_snippet, :internal) }

      it "disallows levels" do
        expect(disallowed_visibility_level?(snippet, public_vis)).to be_falsey
        expect(disallowed_visibility_level?(snippet, internal_vis)).to be_falsey
        expect(disallowed_visibility_level?(snippet, private_vis)).to be_falsey
      end
    end
  end

  describe '#disallowed_visibility_level_by_organization?' do
    let(:organization) { build_stubbed(:organization, organization_visibility_level) }
    let(:group) { build(:group, :private, organization: organization) }

    subject { helper.disallowed_visibility_level_by_organization?(group, visibility_level) }

    where(:organization_visibility_level, :visibility_level, :expected) do
      :public   | public_vis   | false
      :public   | internal_vis | false
      :public   | private_vis  | false
      :private  | public_vis   | true
      :private  | internal_vis | true
      :private  | private_vis  | false
    end

    with_them do
      it { is_expected.to eq expected }
    end
  end

  describe '#disallowed_visibility_level_by_parent?' do
    let(:parent_group) { build_stubbed(:group, parent_group_visibility_level) }
    let(:group) { build(:group, :private, parent: parent_group) }

    subject { helper.disallowed_visibility_level_by_parent?(group, visibility_level) }

    where(:parent_group_visibility_level, :visibility_level, :expected) do
      :public   | public_vis   | false
      :public   | internal_vis | false
      :public   | private_vis  | false
      :internal | public_vis   | true
      :internal | internal_vis | false
      :internal | private_vis  | false
      :private  | public_vis   | true
      :private  | internal_vis | true
      :private  | private_vis  | false
    end

    with_them do
      it { is_expected.to eq expected }
    end
  end

  shared_examples_for 'disallowed visibility level by child' do
    where(:child_visibility_level, :visibility_level, :expected) do
      public_vis   | public_vis   | false
      public_vis   | internal_vis | true
      public_vis   | private_vis  | true
      internal_vis | public_vis   | false
      internal_vis | internal_vis | false
      internal_vis | private_vis  | true
      private_vis  | public_vis   | false
      private_vis  | internal_vis | false
      private_vis  | private_vis  | false
    end

    with_them do
      before do
        child.update!(visibility_level: child_visibility_level)
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#disallowed_visibility_level_by_projects?' do
    let_it_be(:group) { create(:group, :public) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- create is required because child is updated in before hook
    let_it_be_with_reload(:child) { create(:project, group: group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- create is required because child is updated in before hook

    subject { helper.disallowed_visibility_level_by_projects?(group, visibility_level) }

    it_behaves_like 'disallowed visibility level by child'
  end

  describe '#disallowed_visibility_level_by_sub_groups?' do
    let_it_be(:group) { create(:group, :public) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- create is required because child is updated in before hook
    let_it_be_with_reload(:child) { create(:group, parent: group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- create is required because child is updated in before hook

    subject { helper.disallowed_visibility_level_by_sub_groups?(group, visibility_level) }

    it_behaves_like 'disallowed visibility level by child'
  end

  describe '#selected_visibility_level' do
    let_it_be(:group) { create(:group, :public) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- create is required because child is updated in before hook
    let_it_be_with_reload(:project) { create(:project, :internal, group: group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- create is required for fork_project

    let!(:forked_project) { fork_project(project) }

    # This is a subset of all the permutations
    where(:requested_level, :max_allowed, :global_default_level, :restricted_levels, :expected) do
      public_vis   | public_vis   | public_vis   | []           | public_vis
      public_vis   | public_vis   | public_vis   | [public_vis] | internal_vis
      internal_vis | public_vis   | public_vis   | []           | internal_vis
      internal_vis | private_vis  | private_vis  | []           | private_vis
      private_vis  | public_vis   | public_vis   | []           | private_vis
      public_vis   | private_vis  | internal_vis | []           | private_vis
      public_vis   | internal_vis | public_vis   | []           | internal_vis
      public_vis   | private_vis  | public_vis   | []           | private_vis
      public_vis   | internal_vis | internal_vis | []           | internal_vis
      public_vis   | public_vis   | internal_vis | []           | public_vis
    end

    before do
      stub_application_setting(
        restricted_visibility_levels: restricted_levels,
        default_project_visibility: global_default_level
      )
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
    let(:user) { build(:user) }

    subject { helper.available_visibility_levels(form_model) }

    where(:restricted_visibility_levels, :expected) do
      []                          | [private_vis, internal_vis, public_vis]
      [private_vis]               | [internal_vis, public_vis]
      [private_vis, internal_vis] | [public_vis]
      [private_vis, public_vis]   | [internal_vis]
      [internal_vis]              | [private_vis, public_vis]
      [internal_vis, private_vis] | [public_vis]
      [internal_vis, public_vis]  | [private_vis]
      [public_vis]                | [private_vis, internal_vis]
      [public_vis, private_vis]   | [internal_vis]
      [public_vis, internal_vis]  | [private_vis]
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
      allow(helper).to receive(:disallowed_visibility_level?).with(form_model, private_vis).and_return(true)
      allow(helper).to receive(:disallowed_visibility_level?).with(form_model, internal_vis).and_return(false)
      allow(helper).to receive(:disallowed_visibility_level?).with(form_model, public_vis).and_return(false)

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
    let(:available_levels) { [public_vis, internal_vis] }

    it 'returns the selected visibility level' do
      expect(helper.snippets_selected_visibility_level(available_levels, public_vis)).to eq(public_vis)
    end

    it "fallbacks using the lowest available visibility level when selected level isn't available" do
      expect(helper.snippets_selected_visibility_level(available_levels, private_vis)).to eq(internal_vis)
    end
  end

  describe '#multiple_visibility_levels_restricted?' do
    let(:user) { build(:user) }

    subject { helper.multiple_visibility_levels_restricted? }

    where(:restricted_visibility_levels, :expected) do
      [public_vis]                            | false
      [public_vis, internal_vis]              | true
      [public_vis, internal_vis, private_vis] | true
    end

    with_them do
      before do
        allow(helper).to receive(:current_user) { user }
        stub_application_setting(restricted_visibility_levels: restricted_visibility_levels)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#all_visibility_levels_restricted?' do
    let(:user) { build(:user) }

    subject { helper.all_visibility_levels_restricted? }

    where(:restricted_visibility_levels, :expected) do
      [public_vis]                   | false
      [public_vis, internal_vis]     | false
      Gitlab::VisibilityLevel.values | true
    end

    with_them do
      before do
        allow(helper).to receive(:current_user) { user }
        stub_application_setting(restricted_visibility_levels: restricted_visibility_levels)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#all_visibility_levels' do
    subject { helper.all_visibility_levels }

    it 'returns all visibility levels' do
      is_expected.to match_array [private_vis, internal_vis, public_vis]
    end
  end

  describe '#disabled_visibility_level?' do
    let_it_be(:group) { create(:group, :public) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- create is required because child is updated in before hook
    let_it_be_with_reload(:child) { create(:project, group: group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- create is required because child is updated in before hook

    let(:user) { build(:user) }

    subject { helper.disabled_visibility_level?(group, visibility_level) }

    where(:restricted_visibility_levels, :child_visibility_level, :visibility_level, :expected) do
      []                             | public_vis   | public_vis   | false
      []                             | public_vis   | internal_vis | true
      []                             | public_vis   | private_vis  | true
      []                             | internal_vis | public_vis   | false
      []                             | internal_vis | internal_vis | false
      []                             | internal_vis | private_vis  | true
      []                             | private_vis  | public_vis   | false
      []                             | private_vis  | internal_vis | false
      []                             | private_vis  | private_vis  | false

      [public_vis]                   | public_vis   | public_vis   | true
      [public_vis]                   | public_vis   | internal_vis | true
      [public_vis]                   | public_vis   | private_vis  | true
      [public_vis]                   | internal_vis | public_vis   | true
      [public_vis]                   | internal_vis | internal_vis | false
      [public_vis]                   | internal_vis | private_vis  | true

      [internal_vis]                 | public_vis   | public_vis   | false
      [internal_vis]                 | public_vis   | internal_vis | true
      [internal_vis]                 | public_vis   | private_vis  | true
      [internal_vis]                 | internal_vis | public_vis   | false
      [internal_vis]                 | internal_vis | internal_vis | true
      [internal_vis]                 | internal_vis | private_vis  | true

      [public_vis, internal_vis]     | public_vis   | public_vis   | true
      [public_vis, internal_vis]     | public_vis   | internal_vis | true
      [public_vis, internal_vis]     | public_vis   | internal_vis | true

      Gitlab::VisibilityLevel.values | public_vis   | public_vis   | true
      Gitlab::VisibilityLevel.values | public_vis   | internal_vis | true
    end

    with_them do
      before do
        allow(helper).to receive(:current_user) { user }
        stub_application_setting(restricted_visibility_levels: restricted_visibility_levels)

        child.update!(visibility_level: child_visibility_level)
      end

      it { is_expected.to eq expected }
    end
  end

  describe '#restricted_visibility_level?' do
    let(:user) { build(:user) }

    subject { helper.restricted_visibility_level?(visibility_level) }

    where(:restricted_visibility_levels, :visibility_level, :expected) do
      []                             | public_vis   | false
      []                             | internal_vis | false
      []                             | private_vis  | false
      [public_vis]                   | public_vis   | true
      [public_vis]                   | internal_vis | false
      [public_vis]                   | private_vis  | false
      [public_vis, internal_vis]     | public_vis   | true
      [public_vis, internal_vis]     | internal_vis | true
      [public_vis, internal_vis]     | private_vis  | false
      Gitlab::VisibilityLevel.values | public_vis   | true
      Gitlab::VisibilityLevel.values | internal_vis | true
      Gitlab::VisibilityLevel.values | private_vis  | true
    end

    with_them do
      before do
        allow(helper).to receive(:current_user) { user }
        stub_application_setting(restricted_visibility_levels: restricted_visibility_levels)
      end

      it { is_expected.to eq expected }
    end
  end
end
