# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerVersion do
  it_behaves_like 'having unique enum values'

  describe '.not_available' do
    subject { described_class.not_available }

    let!(:runner_version1) { create(:ci_runner_version, version: 'abc123', status: :not_available) }
    let!(:runner_version2) { create(:ci_runner_version, version: 'abc234', status: :recommended) }

    it { is_expected.to match_array([runner_version1]) }
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
