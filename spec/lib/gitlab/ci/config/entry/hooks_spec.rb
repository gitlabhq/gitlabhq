# frozen_string_literal: true

RSpec.describe Gitlab::Ci::Config::Entry::Hooks do
  subject(:entry) { described_class.new(config) }

  before do
    entry.compose!
  end

  describe 'validations' do
    context 'when passing a valid hook' do
      let(:config) { { pre_get_sources_script: ['ls'] } }

      it { is_expected.to be_valid }
    end

    context 'when passing an invalid hook' do
      let(:config) { { x_get_something: ['ls'] } }

      it { is_expected.not_to be_valid }
    end

    context 'when entry config is not a hash' do
      let(:config) { 'ls' }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#value' do
    let(:config) { { pre_get_sources_script: ['ls'] } }

    it 'returns a hash' do
      expect(entry.value).to eq(config)
    end
  end
end
