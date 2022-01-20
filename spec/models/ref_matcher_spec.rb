# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RefMatcher do
  subject(:ref_matcher) { described_class.new(ref_pattern) }

  let(:ref_pattern) { 'v1.0' }

  shared_examples 'matching_refs' do
    context 'when there is no match' do
      let(:ref_pattern) { 'unknown' }

      it { is_expected.to match_array([]) }
    end

    context 'when ref pattern is a wildcard' do
      let(:ref_pattern) { 'v*' }

      it { is_expected.to match_array(refs) }
    end
  end

  describe '#matching' do
    subject { ref_matcher.matching(refs) }

    context 'when refs are strings' do
      let(:refs) { ['v1.0', 'v1.1'] }

      it { is_expected.to match_array([ref_pattern]) }

      it_behaves_like 'matching_refs'
    end

    context 'when refs are ref objects' do
      let(:matching_ref) { double('tag', name: 'v1.0') }
      let(:not_matching_ref) { double('tag', name: 'v1.1') }
      let(:refs) { [matching_ref, not_matching_ref] }

      it { is_expected.to match_array([matching_ref]) }

      it_behaves_like 'matching_refs'
    end
  end

  describe '#matches?' do
    subject { ref_matcher.matches?(ref_name) }

    let(:ref_name) { 'v1.0' }

    it { is_expected.to be_truthy }

    context 'when ref_name is empty' do
      let(:ref_name) { '' }

      it { is_expected.to be_falsey }
    end

    context 'when ref pattern matches wildcard' do
      let(:ref_pattern) { 'v*' }

      it { is_expected.to be_truthy }
    end

    context 'when ref pattern does not match wildcard' do
      let(:ref_pattern) { 'v2.*' }

      it { is_expected.to be_falsey }
    end
  end

  describe '#wildcard?' do
    subject { ref_matcher.wildcard? }

    it { is_expected.to be_falsey }

    context 'when pattern is a wildcard' do
      let(:ref_pattern) { 'v*' }

      it { is_expected.to be_truthy }
    end
  end
end
