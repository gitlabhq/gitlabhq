# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerTagging, feature_category: :runner do
  let_it_be(:group) { create(:group) }

  it { is_expected.to belong_to(:runner).optional(false) }
  it { is_expected.to belong_to(:tag).optional(false) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:runner_type) }
    it { is_expected.to validate_presence_of(:sharding_key_id) }
  end

  describe 'partitioning' do
    context 'with runner' do
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

  describe 'scopes' do
    describe '.for_runner' do
      subject(:for_runner) { described_class.for_runner(runner_ids) }

      let_it_be(:runners) { create_list(:ci_runner, 3, :group, groups: [group]) }

      before_all do
        runners.first.update!(tag_list: 'a')
        runners.second.update!(tag_list: 'b')
        runners.third.update!(tag_list: 'b')
      end

      context 'with runner ids' do
        let(:runner_ids) { runners.take(2).map(&:id) }

        it 'returns requested runner namespaces' do
          is_expected.to eq(runners.take(2).flat_map(&:taggings))
        end
      end

      context 'with runners' do
        let(:runner_ids) { runners.first }

        it 'returns requested runner namespaces' do
          is_expected.to eq(runners.first.taggings)
        end
      end
    end
  end
end
