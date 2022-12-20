# frozen_string_literal: true

require 'gitlab-dangerfiles'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/user_types'

RSpec.describe Tooling::Danger::UserTypes, feature_category: :subscription_cost_management do
  include_context 'with dangerfile'

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:user_types) { fake_danger.new(helper: fake_helper) }

  describe 'changed files' do
    subject(:bot_user_types_change_warning) { user_types.bot_user_types_change_warning }

    before do
      allow(fake_helper).to receive(:modified_files).and_return(modified_files)
      allow(fake_helper).to receive(:changed_lines).and_return(changed_lines)
    end

    context 'when has_user_type.rb file is not impacted' do
      let(:modified_files) { ['app/models/concerns/importable.rb'] }
      let(:changed_lines) { ['+ANY_CHANGES'] }

      it "doesn't add any warnings" do
        expect(user_types).not_to receive(:warn)

        bot_user_types_change_warning
      end
    end

    context 'when the has_user_type.rb file is impacted' do
      let(:modified_files) { ['app/models/concerns/has_user_type.rb'] }

      context 'with BOT_USER_TYPES changes' do
        let(:changed_lines) { ['+BOT_USER_TYPES'] }

        it 'adds warning' do
          expect(user_types).to receive(:warn).with(described_class::BOT_USER_TYPES_CHANGED_WARNING)

          bot_user_types_change_warning
        end
      end

      context 'without BOT_USER_TYPES changes' do
        let(:changed_lines) { ['+OTHER_CHANGES'] }

        it "doesn't add any warnings" do
          expect(user_types).not_to receive(:warn)

          bot_user_types_change_warning
        end
      end
    end
  end
end
