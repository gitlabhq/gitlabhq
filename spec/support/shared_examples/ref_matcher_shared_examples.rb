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
