# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ProjectStudio, feature_category: :user_profile do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  describe '#enabled?' do
    context 'when user is nil' do
      subject { described_class.new(nil).enabled? }

      it { is_expected.to be false }
    end

    context 'when user is present' do
      where(
        :early_access_participant,
        :project_studio_early_access_flag,
        :paneled_view_flag,
        :project_studio_enabled,
        :expected_result
      ) do
        false | false | false | false | false
        false | false | false | true  | false
        false | false | true  | false | false
        false | false | true  | true  | true
        false | true  | false | false | false
        false | true  | false | true  | false
        false | true  | true  | false | false
        false | true  | true  | true  | true
        true  | false | false | false | false
        true  | false | false | true  | false
        true  | false | true  | false | false
        true  | false | true  | true  | true
        true  | true  | false | false | false
        true  | true  | false | true  | true
        true  | true  | true  | false | false
        true  | true  | true  | true  | true
      end

      with_them do
        before do
          user.user_preference.update!(
            early_access_studio_participant: early_access_participant,
            project_studio_enabled: project_studio_enabled
          )
          stub_feature_flags(
            project_studio_early_access: project_studio_early_access_flag,
            paneled_view: paneled_view_flag
          )
        end

        subject { described_class.new(user).enabled? }

        it { is_expected.to be expected_result }
      end
    end
  end

  describe '#available?' do
    context 'when user is nil' do
      subject { described_class.new(nil).available? }

      it { is_expected.to be false }
    end

    context 'when user is present' do
      where(:early_access_participant, :project_studio_early_access_flag, :paneled_view_flag, :expected_result) do
        false | false | false | false
        false | false | true  | true
        false | true  | false | false
        false | true  | true  | true
        true  | false | false | false
        true  | false | true  | true
        true  | true  | false | true
        true  | true  | true  | true
      end

      with_them do
        before do
          user.user_preference.update!(early_access_studio_participant: early_access_participant)
          stub_feature_flags(
            project_studio_early_access: project_studio_early_access_flag,
            paneled_view: paneled_view_flag
          )
        end

        subject { described_class.new(user).available? }

        it { is_expected.to be expected_result }
      end
    end
  end
end
