# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ProjectStudio, feature_category: :user_profile do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  describe '#enabled?' do
    context 'when user is nil' do
      context 'when the Project Studio is not available' do
        before do
          stub_feature_flags(paneled_view: false)
        end

        it 'returns `false`' do
          expect(described_class.new(nil).enabled?).to be false
        end
      end

      context 'when the Project Studio is available' do
        before do
          stub_feature_flags(paneled_view: true)
        end

        it 'returns `true`' do
          expect(described_class.new(nil).enabled?).to be true
        end
      end
    end

    context 'when user is present' do
      let(:project_studio) { described_class.new(user) }

      context 'when the Project Studio is not available' do
        before do
          stub_feature_flags(paneled_view: false)
          stub_env('GLCI_OVERRIDE_PROJECT_STUDIO_ENABLED', 'false')
          user.user_preference.update!(project_studio_enabled: true)
        end

        it 'returns `false`' do
          expect(project_studio.enabled?).to be false
        end
      end

      context 'when the Project Studio is available' do
        before do
          stub_feature_flags(paneled_view: true)
        end

        context 'when `project_studio_enabled` is `true`' do
          before do
            user.user_preference.update!(project_studio_enabled: true)
          end

          it 'returns `true`' do
            expect(project_studio.enabled?).to be true
          end
        end

        context 'when `project_studio_enabled` is `false`' do
          before do
            user.user_preference.update!(project_studio_enabled: false)
          end

          context "when the user hasn't updated their setting yet" do
            before do
              user.user_preference.update!(new_ui_enabled: nil)
            end

            it 'returns true' do
              expect(project_studio.enabled?).to be true
            end
          end

          context 'when the user has already updated their setting' do
            before do
              user.user_preference.update!(new_ui_enabled: new_ui_enabled)
            end

            where(
              :new_ui_enabled,
              :expected_result
            ) do
              true  | true
              false | false
            end

            with_them do
              it 'returns expected result' do
                expect(project_studio.enabled?).to be expected_result
              end
            end
          end
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

    context 'when user is present' do
      where(
        :paneled_view_flag,
        :project_studio_enabled,
        :expected_result
      ) do
        false | false | true
        true | false | true
        false | true | true
        true | true | true
      end

      with_them do
        before do
          user.user_preference.update!(new_ui_enabled: project_studio_enabled)
          stub_feature_flags(paneled_view: paneled_view_flag)
        end

        it 'returns expected result' do
          expect(described_class.new(user).enabled?).to be expected_result
        end
      end
    end
  end

  describe '#available?' do
    context 'when user is nil' do
      where(:paneled_view_flag, :expected_result) do
        false | false
        true  | true
      end

      with_them do
        before do
          stub_feature_flags(paneled_view: paneled_view_flag)
        end

        it 'returns expected result' do
          expect(described_class.new(nil).available?).to be expected_result
        end
      end
    end

    context 'when user is present' do
      where(:paneled_view_flag, :expected_result) do
        false | false
        true  | true
      end

      with_them do
        before do
          stub_feature_flags(paneled_view: paneled_view_flag)
        end

        it 'returns expected result' do
          expect(described_class.new(user).available?).to be expected_result
        end
      end
    end
  end
end
