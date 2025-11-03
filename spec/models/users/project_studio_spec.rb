# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ProjectStudio, feature_category: :user_profile do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  describe '#enabled?' do
    context 'when user is nil' do
      context 'without studio_cookie' do
        it 'returns false' do
          expect(described_class.new(nil).enabled?).to be false
        end
      end

      context 'with studio_cookie set to true' do
        it 'returns true' do
          expect(described_class.new(nil, studio_cookie: 'true').enabled?).to be true
        end
      end

      context 'with studio_cookie set to false' do
        it 'returns false' do
          expect(described_class.new(nil, studio_cookie: 'false').enabled?).to be false
        end
      end

      context 'with studio_cookie set to nil' do
        it 'returns false' do
          expect(described_class.new(nil, studio_cookie: nil).enabled?).to be false
        end
      end
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

        it 'returns expected result' do
          expect(described_class.new(user).enabled?).to be expected_result
        end
      end

      context 'when user is present, ignores cookie value' do
        before do
          user.user_preference.update!(
            early_access_studio_participant: false,
            project_studio_enabled: false
          )
          stub_feature_flags(
            project_studio_early_access: false,
            paneled_view: true
          )
        end

        it 'uses user settings instead of cookie' do
          expect(described_class.new(user, studio_cookie: 'true').enabled?).to be false
        end
      end
    end
  end

  describe '#enabled? with GLCI_OVERRIDE_PROJECT_STUDIO_ENABLED set to true' do
    before do
      stub_env('GLCI_OVERRIDE_PROJECT_STUDIO_ENABLED', 'true')
    end

    context 'when user is nil' do
      it 'returns true' do
        expect(described_class.new(nil).enabled?).to be true
      end
    end

    context 'when user is nil with cookie set to false' do
      it 'ENV override takes precedence over cookie' do
        expect(described_class.new(nil, studio_cookie: 'false').enabled?).to be true
      end
    end

    context 'when user is present' do
      where(
        :early_access_participant,
        :project_studio_early_access_flag,
        :paneled_view_flag,
        :project_studio_enabled,
        :expected_result
      ) do
        false | false | false | false | true
        false | false | false | true  | true
        false | false | true  | false | true
        false | false | true  | true  | true
        false | true  | false | false | true
        false | true  | false | true  | true
        false | true  | true  | false | true
        false | true  | true  | true  | true
        true  | false | false | false | true
        true  | false | false | true  | true
        true  | false | true  | false | true
        true  | false | true  | true  | true
        true  | true  | false | false | true
        true  | true  | false | true  | true
        true  | true  | true  | false | true
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

        it 'returns expected result' do
          expect(described_class.new(user).enabled?).to be expected_result
        end
      end
    end
  end

  describe '#available?' do
    context 'when user is nil' do
      context 'without studio_cookie' do
        it 'returns false' do
          expect(described_class.new(nil).available?).to be false
        end
      end

      context 'with studio_cookie set to true' do
        it 'returns true' do
          expect(described_class.new(nil, studio_cookie: 'true').available?).to be true
        end
      end

      context 'with studio_cookie set to false' do
        it 'returns false' do
          expect(described_class.new(nil, studio_cookie: 'false').available?).to be false
        end
      end

      context 'with studio_cookie set to nil' do
        it 'returns false' do
          expect(described_class.new(nil, studio_cookie: nil).available?).to be false
        end
      end
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

        it 'returns expected result' do
          expect(described_class.new(user).available?).to be expected_result
        end
      end

      context 'when user is present, ignores cookie value' do
        before do
          user.user_preference.update!(early_access_studio_participant: false)
          stub_feature_flags(
            project_studio_early_access: false,
            paneled_view: false
          )
        end

        it 'uses user settings instead of cookie' do
          expect(described_class.new(user, studio_cookie: 'true').available?).to be false
        end
      end
    end
  end
end
