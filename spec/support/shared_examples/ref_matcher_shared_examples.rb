# frozen_string_literal: true

# All of these examples expect a `ref_matcher` which has been initialized using
# the `ref_pattern` var e.g.
#   subject(:ref_matcher) { RefMatcher.new(ref_pattern) }
#   subject(:ref_matcher) { ProtectedBranch.new(name: ref_pattern) }
RSpec.shared_examples 'RefMatcher#matching' do
  subject(:matching) { ref_matcher.matching(refs) }

  shared_examples 'returns `refs` matching `ref_pattern`' do
    context 'when there is a match' do
      let(:ref_pattern) { exact_ref_pattern }

      it { is_expected.to match_array(exact_matches) }
    end

    context 'when there is no match' do
      let(:ref_pattern) { 'unknown' }

      it { is_expected.to be_empty }
    end

    context 'when ref pattern is a wildcard' do
      let(:ref_pattern) { wildcard_ref_pattern }

      it { is_expected.to match_array(wildcard_matches) }
    end
  end

  context 'when refs are strings' do
    let(:refs) { ['v1.0', 'v1.1', 'v2.0'] }
    let(:exact_ref_pattern) { 'v1.0' }
    let(:exact_matches) { ['v1.0'] }
    let(:wildcard_ref_pattern) { 'v1.*' }
    let(:wildcard_matches) { ['v1.0', 'v1.1'] }

    it_behaves_like 'returns `refs` matching `ref_pattern`'
  end

  context 'when refs are ref objects' do
    let(:v_one) { instance_double('Gitlab::Git::Ref', name: 'v1.0') }
    let(:v_one_one) { instance_double('Gitlab::Git::Ref', name: 'v1.1') }
    let(:v_two) { instance_double('Gitlab::Git::Ref', name: 'v2.0') }
    let(:refs) { [v_one, v_one_one, v_two] }
    let(:exact_ref_pattern) { 'v1.0' }
    let(:exact_matches) { [v_one] }
    let(:wildcard_ref_pattern) { 'v1.*' }
    let(:wildcard_matches) { [v_one, v_one_one] }

    it_behaves_like 'returns `refs` matching `ref_pattern`'
  end
end

RSpec.shared_examples 'RefMatcher#matches?' do
  let(:ref_pattern) { 'v1.0' }
  let(:ref_name) { 'v1.0' }

  subject(:matches) { ref_matcher.matches?(ref_name) }

  context 'when ref_pattern matches ref_name' do
    it { is_expected.to be_truthy }
  end

  context 'when ref_name is empty' do
    let(:ref_name) { '' }

    it { is_expected.to be_falsey }
  end

  context 'when ref_pattern wildcard matches ref_name' do
    let(:ref_pattern) { 'v*' }

    it { is_expected.to be_truthy }
  end

  context 'when ref_pattern wildcard does not match ref_name' do
    let(:ref_pattern) { 'v2.*' }

    it { is_expected.to be_falsey }
  end

  context 'when ref_pattern with ReDoS' do
    let(:ref_pattern) { '**************a' }
    let(:ref_name) { 'aaaaaaaaaaaaaaaaaaaaa' }

    it 'does not cause catastrophic backtracking' do
      expect do
        Timeout.timeout(10.seconds) do
          is_expected.to be_truthy
        end
      end.not_to raise_error
    end
  end
end

RSpec.shared_examples 'RefMatcher#overlaps?' do
  subject(:overlaps) { ref_matcher.overlaps?(other_pattern) }

  context 'when both are exact matches and equal' do
    let(:ref_pattern) { 'main' }
    let(:other_pattern) { 'main' }

    it { is_expected.to be true }
  end

  context 'when both are exact matches and different' do
    let(:ref_pattern) { 'main' }
    let(:other_pattern) { 'develop' }

    it { is_expected.to be false }
  end

  context 'when self is wildcard and other is literal that matches' do
    let(:ref_pattern) { 'prod*' }
    let(:other_pattern) { 'production' }

    it { is_expected.to be true }
  end

  context 'when self is wildcard and other is literal that does not match' do
    let(:ref_pattern) { 'prod*' }
    let(:other_pattern) { 'staging' }

    it { is_expected.to be false }
  end

  context 'when self is literal and other is wildcard that matches' do
    let(:ref_pattern) { 'production' }
    let(:other_pattern) { 'prod*' }

    it { is_expected.to be true }
  end

  context 'when self is literal and other is wildcard that does not match' do
    let(:ref_pattern) { 'staging' }
    let(:other_pattern) { 'prod*' }

    it { is_expected.to be false }
  end

  context 'when both are wildcards with overlapping sets (superset/subset)' do
    let(:ref_pattern) { 'prod*' }
    let(:other_pattern) { 'production*' }

    it { is_expected.to be true }
  end

  context 'when both are wildcards with overlapping sets (narrower policy pattern)' do
    let(:ref_pattern) { 'production-v1*' }
    let(:other_pattern) { 'production-*' }

    it { is_expected.to be true }
  end

  context 'when both are wildcards with non-overlapping sets' do
    let(:ref_pattern) { 'release/*' }
    let(:other_pattern) { 'release-*' }

    it { is_expected.to be false }
  end

  context 'when one is universal wildcard' do
    let(:ref_pattern) { '*' }
    let(:other_pattern) { 'anything*' }

    it { is_expected.to be true }
  end

  context 'when both are universal wildcards' do
    let(:ref_pattern) { '*' }
    let(:other_pattern) { '*' }

    it { is_expected.to be true }
  end

  context 'when patterns end with different literal chars' do
    let(:ref_pattern) { 'a*b' }
    let(:other_pattern) { 'a*c' }

    it { is_expected.to be false }
  end

  context 'when suffix wildcards overlap' do
    let(:ref_pattern) { '*-release' }
    let(:other_pattern) { 'v*-release' }

    it { is_expected.to be true }
  end

  context 'when prefix and suffix wildcards overlap (string "a" matches both)' do
    let(:ref_pattern) { 'a*' }
    let(:other_pattern) { '*a' }

    it { is_expected.to be true }
  end

  context 'when self pattern is blank' do
    let(:ref_pattern) { '' }
    let(:other_pattern) { 'prod*' }

    it { is_expected.to be false }
  end

  context 'when other pattern is blank' do
    let(:ref_pattern) { 'prod*' }
    let(:other_pattern) { '' }

    it { is_expected.to be false }
  end

  context 'when self pattern is nil' do
    let(:ref_pattern) { nil }
    let(:other_pattern) { 'prod*' }

    it { is_expected.to be false }
  end

  context 'when both patterns are identical wildcards' do
    let(:ref_pattern) { 'release-*' }
    let(:other_pattern) { 'release-*' }

    it { is_expected.to be true }
  end

  context 'when patterns have multiple wildcards' do
    let(:ref_pattern) { 'a*b*c' }
    let(:other_pattern) { 'a*c' }

    it { is_expected.to be true }
  end

  context 'when patterns have multiple wildcards and do not overlap' do
    let(:ref_pattern) { 'a*b*c' }
    let(:other_pattern) { 'x*y*z' }

    it { is_expected.to be false }
  end

  context 'when checking symmetry (a.overlaps?(b) == b.overlaps?(a))' do
    where(:pattern_a, :pattern_b, :expected) do
      [
        ['prod*',          'production*',   true],
        ['production-v1*', 'production-*',  true],
        ['release/*',      'release-*',     false],
        ['*',              'anything*',     true],
        ['a*b',            'a*c',           false],
        ['a*',             '*a',            true],
        ['main',           'main',          true],
        ['main',           'develop',       false]
      ]
    end

    with_them do
      let(:ref_pattern) { pattern_a }
      let(:other_pattern) { pattern_b }

      it 'is symmetric' do
        forward = described_class.new(pattern_a).overlaps?(pattern_b)
        reverse = described_class.new(pattern_b).overlaps?(pattern_a)
        expect(forward).to eq(reverse),
          "asymmetry: #{pattern_a}.overlaps?(#{pattern_b})=#{forward} but reverse=#{reverse}"
        expect(forward).to eq(expected)
      end
    end
  end

  context 'with ReDoS-style patterns containing many wildcards' do
    let(:ref_pattern) { '**************a' }
    let(:other_pattern) { '**************b' }

    it 'does not cause catastrophic backtracking' do
      expect do
        Timeout.timeout(10.seconds) do
          is_expected.to be false
        end
      end.not_to raise_error
    end
  end

  context 'when self pattern exceeds MAX_OVERLAP_PATTERN_LENGTH' do
    let(:ref_pattern) { 'a' * (RefMatcher::MAX_OVERLAP_PATTERN_LENGTH + 1) }
    let(:other_pattern) { 'a*' }

    it { is_expected.to be false }
  end

  context 'when other pattern exceeds MAX_OVERLAP_PATTERN_LENGTH' do
    let(:ref_pattern) { 'a*' }
    let(:other_pattern) { 'a' * (RefMatcher::MAX_OVERLAP_PATTERN_LENGTH + 1) }

    it { is_expected.to be false }
  end

  context 'when patterns are exactly at MAX_OVERLAP_PATTERN_LENGTH' do
    let(:ref_pattern) { "#{'a' * (RefMatcher::MAX_OVERLAP_PATTERN_LENGTH - 1)}*" }
    let(:other_pattern) { "#{'a' * (RefMatcher::MAX_OVERLAP_PATTERN_LENGTH - 1)}*" }

    it { is_expected.to be true }
  end
end

RSpec.shared_examples 'RefMatcher#wildcard?' do
  subject(:wildcard) { ref_matcher.wildcard? }

  context 'when pattern is not a wildcard' do
    let(:ref_pattern) { 'v1' }

    it { is_expected.to be_falsey }
  end

  context 'when pattern is a wildcard' do
    let(:ref_pattern) { 'v*' }

    it { is_expected.to be_truthy }
  end
end
