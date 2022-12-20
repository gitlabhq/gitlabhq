# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerVersion, feature_category: :runner_fleet do
  let_it_be(:runner_version_recommended) do
    create(:ci_runner_version, version: 'abc234', status: :recommended)
  end

  let_it_be(:runner_version_not_available) do
    create(:ci_runner_version, version: 'abc123', status: :not_available)
  end

  it_behaves_like 'having unique enum values'

  describe '.not_available' do
    subject { described_class.not_available }

    it { is_expected.to match_array([runner_version_not_available]) }
  end

  describe '.potentially_outdated' do
    subject { described_class.potentially_outdated }

    let_it_be(:runner_version_nil) { create(:ci_runner_version, version: 'abc345', status: nil) }
    let_it_be(:runner_version_available) do
      create(:ci_runner_version, version: 'abc456', status: :available)
    end

    it 'contains any valid or unprocessed runner version that is not already recommended' do
      is_expected.to match_array(
        [runner_version_nil, runner_version_not_available, runner_version_available]
      )
    end
  end

  describe 'validation' do
    context 'when runner version is too long' do
      let(:runner_version) { build(:ci_runner_version, version: 'a' * 2049) }

      it 'is not valid' do
        expect(runner_version).to be_invalid
      end
    end
  end
end
