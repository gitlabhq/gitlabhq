# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::Ci::Config::Entry::Need do
  subject(:need) { described_class.new(config) }

  context 'when job is specified' do
    let(:config) { 'job_name' }

    describe '#valid?' do
      it { is_expected.to be_valid }
    end

    describe '#value' do
      it 'returns job needs configuration' do
        expect(need.value).to eq(name: 'job_name')
      end
    end
  end

  context 'when need is empty' do
    let(:config) { '' }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'is returns an error about an empty config' do
        expect(need.errors)
          .to contain_exactly("job config can't be blank")
      end
    end
  end
end
