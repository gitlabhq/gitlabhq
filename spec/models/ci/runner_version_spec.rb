# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerVersion, feature_category: :runner_fleet do
  let_it_be(:runner_version_upgrade_recommended) do
    create(:ci_runner_version, version: 'abc234', status: :recommended)
  end

  let_it_be(:runner_version_upgrade_unavailable) do
    create(:ci_runner_version, version: 'abc123', status: :unavailable)
  end

  it { is_expected.to have_many(:runner_machines).with_foreign_key(:version) }

  it_behaves_like 'having unique enum values'

  describe '.unavailable' do
    subject { described_class.unavailable }

    it { is_expected.to match_array([runner_version_upgrade_unavailable]) }
  end

  describe '.potentially_outdated' do
    subject { described_class.potentially_outdated }

    let_it_be(:runner_version_nil) { create(:ci_runner_version, version: 'abc345', status: nil) }
    let_it_be(:runner_version_upgrade_available) do
      create(:ci_runner_version, version: 'abc456', status: :available)
    end

    it 'contains any valid or unprocessed runner version that is not already recommended' do
      is_expected.to match_array(
        [runner_version_nil, runner_version_upgrade_unavailable, runner_version_upgrade_available]
      )
    end
  end

  describe 'validation' do
    it { is_expected.to validate_length_of(:version).is_at_most(2048) }
  end
end
