# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserPreference, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  let(:user_preference) { create(:user_preference, user: user) }

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:time_display_relative).in_array([true, false]) }
    it { is_expected.to validate_inclusion_of(:render_whitespace_in_code).in_array([true, false]) }

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
      it { is_expected.to validate_inclusion_of(:pass_user_identities_to_ci_jwt).in_array([true, false]) }
      it { is_expected.not_to allow_value("").for(:pass_user_identities_to_ci_jwt) }
    end

    describe 'visibility_pipeline_id_type' do
      it 'is set to 0 by default' do
        pref = described_class.new

        expect(pref.visibility_pipeline_id_type).to eq('id')
      end

      it { is_expected.to define_enum_for(:visibility_pipeline_id_type).with_values(id: 0, iid: 1) }
    end

    describe 'user belongs to the home organization' do
      let_it_be(:organization) { create(:organization) }

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

  describe '#tab_width' do
    it 'is set to 8 by default' do
      # Intentionally not using factory here to test the constructor.
      pref = described_class.new

      expect(pref.tab_width).to eq(8)
    end

    it 'returns default value when assigning nil' do
      pref = described_class.new(tab_width: nil)

      expect(pref.tab_width).to eq(8)
    end
  end

  describe '#tab_width=' do
    it 'sets to default value when nil' do
      pref = described_class.new(tab_width: nil)

      expect(pref.read_attribute(:tab_width)).to eq(8)
    end

    it 'sets user values' do
      pref = described_class.new(tab_width: 12)

      expect(pref.read_attribute(:tab_width)).to eq(12)
    end
  end

  describe '#time_display_relative' do
    it 'is set to true by default' do
      pref = described_class.new

      expect(pref.time_display_relative).to eq(true)
    end

    it 'returns default value when assigning nil' do
      pref = described_class.new(time_display_relative: nil)

      expect(pref.time_display_relative).to eq(true)
    end

    it 'returns assigned value' do
      pref = described_class.new(time_display_relative: false)

      expect(pref.time_display_relative).to eq(false)
    end
  end

  describe '#time_display_relative=' do
    it 'sets to default value when nil' do
      pref = described_class.new(time_display_relative: nil)

      expect(pref.read_attribute(:time_display_relative)).to eq(true)
    end

    it 'sets user values' do
      pref = described_class.new(time_display_relative: false)

      expect(pref.read_attribute(:time_display_relative)).to eq(false)
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

  describe '#render_whitespace_in_code' do
    it 'is set to false by default' do
      pref = described_class.new

      expect(pref.render_whitespace_in_code).to eq(false)
    end

    it 'returns default value when assigning nil' do
      pref = described_class.new(render_whitespace_in_code: nil)

      expect(pref.render_whitespace_in_code).to eq(false)
    end

    it 'returns assigned value' do
      pref = described_class.new(render_whitespace_in_code: true)

      expect(pref.render_whitespace_in_code).to eq(true)
    end
  end

  describe '#render_whitespace_in_code=' do
    it 'sets to default value when nil' do
      pref = described_class.new(render_whitespace_in_code: nil)

      expect(pref.read_attribute(:render_whitespace_in_code)).to eq(false)
    end

    it 'sets user values' do
      pref = described_class.new(render_whitespace_in_code: true)

      expect(pref.read_attribute(:render_whitespace_in_code)).to eq(true)
    end
  end
end
