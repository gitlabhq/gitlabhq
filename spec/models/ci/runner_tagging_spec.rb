# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerTagging, feature_category: :runner do
  it { is_expected.to belong_to(:runner).optional(false) }
  it { is_expected.to belong_to(:tag).optional(false) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:runner_type) }
    it { is_expected.to validate_presence_of(:sharding_key_id) }
  end

  describe 'partitioning' do
    context 'with runner' do
      let_it_be(:group) { create(:group) }
      let_it_be(:runner) { FactoryBot.build(:ci_runner, :group, groups: [group]) }
      let_it_be(:runner_tagging) { FactoryBot.build(:ci_runner_tagging, runner: runner) }

      it 'sets runner_type to the current partition value' do
        expect { runner_tagging.valid? }.to change { runner_tagging.runner_type }.to('group_type')
      end

      context 'when it is already set' do
        let_it_be(:runner_tagging) { FactoryBot.build(:ci_runner_tagging, runner_type: :project_type) }

        it 'does not change the runner_type value' do
          expect { runner_tagging.valid? }.not_to change { runner_tagging.runner_type }
        end
      end
    end
  end
end
