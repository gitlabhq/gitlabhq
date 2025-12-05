# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ProjectStudio, feature_category: :user_profile do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  describe "sanity check that project studio is default enabled" do
    before do
      # -- temporary Project Studio rollout
      skip 'Test not applicable in classic UI' if ENV["GLCI_OVERRIDE_PROJECT_STUDIO_ENABLED"] == "false"
    end

    it "passes" do
      expect(described_class.new(user).enabled?).to be(true)
      expect(described_class.enabled_for_user?(user)).to be(true)
    end
  end

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
        end

        it 'returns `false`' do
          expect(project_studio.enabled?).to be false
        end
      end

      context 'when the Project Studio is available' do
        before do
          stub_feature_flags(paneled_view: true)
        end

        it 'returns true' do
          expect(project_studio.enabled?).to be true
        end
      end
    end
  end

  describe '#enabled? with GLCI_OVERRIDE_PROJECT_STUDIO_ENABLED set to false' do
    before do
      stub_env('GLCI_OVERRIDE_PROJECT_STUDIO_ENABLED', 'false')
    end

    context 'when user is nil' do
      it 'returns false' do
        expect(described_class.new(nil).enabled?).to be false
      end
    end

    context 'when user is present' do
      where(
        :paneled_view_flag,
        :expected_result
      ) do
        false | false
        true  | false
      end

      with_them do
        before do
          stub_feature_flags(paneled_view: paneled_view_flag)
        end

        it 'returns expected result' do
          expect(described_class.new(user).enabled?).to be expected_result
        end
      end
    end
  end
end
