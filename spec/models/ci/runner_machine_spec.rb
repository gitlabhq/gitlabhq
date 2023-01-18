# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerMachine, feature_category: :runner_fleet, type: :model do
  it_behaves_like 'having unique enum values'

  it { is_expected.to belong_to(:runner) }

  describe 'validation' do
    it { is_expected.to validate_presence_of(:runner) }
    it { is_expected.to validate_presence_of(:machine_xid) }
    it { is_expected.to validate_length_of(:machine_xid).is_at_most(64) }
    it { is_expected.to validate_length_of(:version).is_at_most(2048) }
    it { is_expected.to validate_length_of(:revision).is_at_most(255) }
    it { is_expected.to validate_length_of(:platform).is_at_most(255) }
    it { is_expected.to validate_length_of(:architecture).is_at_most(255) }
    it { is_expected.to validate_length_of(:ip_address).is_at_most(1024) }

    context 'when runner has config' do
      it 'is valid' do
        runner_machine = build(:ci_runner_machine, config: { gpus: "all" })

        expect(runner_machine).to be_valid
      end
    end

    context 'when runner has an invalid config' do
      it 'is invalid' do
        runner_machine = build(:ci_runner_machine, config: { test: 1 })

        expect(runner_machine).not_to be_valid
      end
    end
  end

  describe '.stale', :freeze_time do
    subject { described_class.stale.ids }

    let!(:runner_machine1) { create(:ci_runner_machine, created_at: 8.days.ago, contacted_at: 7.days.ago) }
    let!(:runner_machine2) { create(:ci_runner_machine, created_at: 7.days.ago, contacted_at: nil) }
    let!(:runner_machine3) { create(:ci_runner_machine, created_at: 5.days.ago, contacted_at: nil) }
    let!(:runner_machine4) do
      create(:ci_runner_machine, created_at: (7.days - 1.second).ago, contacted_at: (7.days - 1.second).ago)
    end

    it 'returns stale runner machines' do
      is_expected.to match_array([runner_machine1.id, runner_machine2.id])
    end
  end
end
