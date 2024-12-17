# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserPreference, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  let(:user_preference) { create(:user_preference, user: user) }

  describe 'validations' do
    it do
      is_expected.to validate_numericality_of(:tab_width)
                       .only_integer
                       .is_greater_than_or_equal_to(Gitlab::TabWidth::MIN)
                       .is_less_than_or_equal_to(Gitlab::TabWidth::MAX)
    end

    describe 'diffs_deletion_color and diffs_addition_color' do
      using RSpec::Parameterized::TableSyntax

      where(color: [
        '#000000',
              '#123456',
              '#abcdef',
              '#AbCdEf',
              '#ffffff',
              '#fFfFfF',
              '#000',
              '#123',
              '#abc',
              '#AbC',
              '#fff',
              '#fFf',
              ''
      ])

      with_them do
        it { is_expected.to allow_value(color).for(:diffs_deletion_color) }
        it { is_expected.to allow_value(color).for(:diffs_addition_color) }
      end

      where(color: [
        '#1',
              '#12',
              '#1234',
              '#12345',
              '#1234567',
              '123456',
              '#12345x'
      ])

      with_them do
        it { is_expected.not_to allow_value(color).for(:diffs_deletion_color) }
        it { is_expected.not_to allow_value(color).for(:diffs_addition_color) }
      end
    end

    describe 'pass_user_identities_to_ci_jwt' do
      it { is_expected.not_to allow_value("").for(:pass_user_identities_to_ci_jwt) }
    end

    describe 'visibility_pipeline_id_type' do
      it 'is set to 0 by default' do
        pref = described_class.new

        expect(pref.visibility_pipeline_id_type).to eq('id')
      end

      it { is_expected.to define_enum_for(:visibility_pipeline_id_type) }
    end

    describe 'extensions_marketplace_opt_in_status' do
      it 'is set to 0 by default' do
        pref = described_class.new

        expect(pref.extensions_marketplace_opt_in_status).to eq('unset')
      end

      it do
        is_expected
          .to define_enum_for(:extensions_marketplace_opt_in_status).with_values(unset: 0, enabled: 1, disabled: 2)
      end
    end

    describe 'organization_groups_projects_display' do
      it 'is set to 0 by default' do
        pref = described_class.new

        expect(pref.organization_groups_projects_display).to eq('projects')
      end

      it { is_expected.to define_enum_for(:organization_groups_projects_display).with_values(projects: 0, groups: 1) }
    end

    describe 'user belongs to the home organization' do
      let_it_be(:organization) { create(:organization) }

      before do
        user_preference.home_organization = organization
      end

      context 'when user is an organization user' do
        before do
          create(:organization_user, organization: organization, user: user)
        end

        it 'does not add any validation errors' do
          user_preference.home_organization = organization

          expect(user_preference).to be_valid
          expect(user_preference.errors).to be_empty
        end
      end

      context 'when user is not an organization user' do
        it 'adds a validation error' do
          user_preference.home_organization = organization

          expect(user_preference).to be_invalid
          expect(user_preference.errors.messages[:user].first).to eq(_("is not part of the given organization"))
        end
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:home_organization).class_name('Organizations::Organization').optional }
  end

  describe 'notes filters global keys' do
    it 'contains expected values' do
      expect(UserPreference::NOTES_FILTERS.keys).to match_array([:all_notes, :only_comments, :only_activity])
    end
  end

  describe '#set_notes_filter' do
    let(:issuable) { build_stubbed(:issue) }

    shared_examples 'setting system notes' do
      it 'returns updated discussion filter' do
        filter_name =
          user_preference.set_notes_filter(filter, issuable)

        expect(filter_name).to eq(filter)
      end

      it 'updates discussion filter for issuable class' do
        user_preference.set_notes_filter(filter, issuable)

        expect(user_preference.reload.issue_notes_filter).to eq(filter)
      end
    end

    context 'when filter is set to all notes' do
      let(:filter) { described_class::NOTES_FILTERS[:all_notes] }

      it_behaves_like 'setting system notes'
    end

    context 'when filter is set to only comments' do
      let(:filter) { described_class::NOTES_FILTERS[:only_comments] }

      it_behaves_like 'setting system notes'
    end

    context 'when filter is set to only activity' do
      let(:filter) { described_class::NOTES_FILTERS[:only_activity] }

      it_behaves_like 'setting system notes'
    end

    context 'when notes_filter parameter is invalid' do
      let(:only_comments) { described_class::NOTES_FILTERS[:only_comments] }

      it 'returns the current notes filter' do
        user_preference.set_notes_filter(only_comments, issuable)

        expect(user_preference.set_notes_filter(non_existing_record_id, issuable)).to eq(only_comments)
      end
    end
  end

  describe 'sort_by preferences' do
    shared_examples_for 'a sort_by preference' do
      it 'allows nil sort fields' do
        user_preference.update!(attribute => nil)

        expect(user_preference).to be_valid
      end
    end

    context 'merge_requests_sort attribute' do
      let(:attribute) { :merge_requests_sort }

      it_behaves_like 'a sort_by preference'
    end

    context 'issues_sort attribute' do
      let(:attribute) { :issues_sort }

      it_behaves_like 'a sort_by preference'
    end
  end

  describe '#project_shortcut_buttons' do
    it 'is set to true by default' do
      pref = described_class.new

      expect(pref.project_shortcut_buttons).to eq(true)
    end

    it 'returns assigned value' do
      pref = described_class.new(project_shortcut_buttons: false)

      expect(pref.project_shortcut_buttons).to eq(false)
    end
  end

  describe '#keyboard_shortcuts_enabled' do
    it 'is set to true by default' do
      pref = described_class.new

      expect(pref.keyboard_shortcuts_enabled).to eq(true)
    end

    it 'returns assigned value' do
      pref = described_class.new(keyboard_shortcuts_enabled: false)

      expect(pref.keyboard_shortcuts_enabled).to eq(false)
    end
  end

  describe '#early_access_event_tracking?' do
    let(:participant) { true }
    let(:tracking) { true }
    let(:user_preference) do
      build(:user_preference, early_access_program_participant: participant, early_access_program_tracking: tracking)
    end

    context 'when user participate in beta and agreed on tracking' do
      it { expect(user_preference.early_access_event_tracking?).to be true }
    end

    context 'when user does not participate' do
      let(:participant) { false }

      it { expect(user_preference.early_access_event_tracking?).to be false }
    end

    context 'when user did not agree on tracking' do
      let(:tracking) { false }

      it { expect(user_preference.early_access_event_tracking?).to be false }
    end
  end

  describe '#extensions_marketplace_enabled' do
    where(:opt_in_status, :expected_value) do
      [
        ["enabled", true],
        ["disabled", false],
        ["unset", false]
      ]
    end

    with_them do
      it 'returns boolean from extensions_marketplace_opt_in_status' do
        user_preference.update!(extensions_marketplace_opt_in_status: opt_in_status)

        expect(user_preference.extensions_marketplace_enabled).to be expected_value
      end
    end
  end

  describe '#extensions_marketplace_enabled=' do
    where(:value, :expected_opt_in_status) do
      [
        [true, "enabled"],
        [false, "disabled"],
        [0, "disabled"],
        [1, "enabled"]
      ]
    end

    with_them do
      it 'updates extensions_marketplace_opt_in_status' do
        user_preference.update!(extensions_marketplace_opt_in_status: 'unset')

        user_preference.extensions_marketplace_enabled = value

        expect(user_preference.extensions_marketplace_opt_in_status).to be expected_opt_in_status
      end
    end
  end

  describe '#dpop_enabled' do
    let(:pref) { described_class.new(args) }

    context 'when no arguments are provided' do
      let(:args) { {} }

      it 'is set to false by default' do
        expect(pref.dpop_enabled).to eq(false)
      end
    end

    context 'when dpop_enabled is set to nil' do
      let(:args) { { dpop_enabled: nil } }

      it 'returns default value' do
        expect(pref.dpop_enabled).to eq(false)
      end
    end

    context 'when dpop_enabled is set to true' do
      let(:args) { { dpop_enabled: true } }

      it 'returns assigned value' do
        expect(pref.dpop_enabled).to eq(true)
      end
    end
  end

  describe '#text_editor' do
    let(:pref) { described_class.new(text_editor_type: text_editor_type) }
    let(:text_editor_type) { :not_set }

    context 'when text_editor_type is not_set' do
      it 'returns not_set' do
        expect(pref.text_editor).to eq "not_set"
      end

      it 'returns false for default_text_editor_enabled' do
        expect(pref.default_text_editor_enabled).to be false
      end
    end

    context 'when text_editor_type is set' do
      where(:text_editor_type) { %w[plain_text_editor rich_text_editor] }

      with_them do
        it 'returns assigned text_editor_type' do
          expect(pref.text_editor).to eq(text_editor_type)
        end

        it 'returns true for default_text_editor_enabled' do
          expect(pref.default_text_editor_enabled).to be true
        end
      end
    end
  end

  describe '#default_text_editor_enabled' do
    let(:pref) { described_class.new(default_text_editor_enabled: default_text_editor_enabled) }

    where(:default_text_editor_enabled, :text_editor_type) do
      [
        [true, "rich_text_editor"],
        [false, "not_set"]
      ]
    end

    with_them do
      it 'assigns correctly' do
        expect(pref.default_text_editor_enabled).to eq(default_text_editor_enabled)
      end

      it 'returns correct value for text_editor' do
        expect(pref.text_editor).to eq(text_editor_type)
      end
    end
  end
end
