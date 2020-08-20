# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Normalizer::MatrixStrategy do
  describe '.applies_to?' do
    subject { described_class.applies_to?(config) }

    context 'with hash that has :matrix key' do
      let(:config) { { matrix: [] } }

      it { is_expected.to be_truthy }
    end

    context 'with hash that does not have :matrix key' do
      let(:config) { { number: [] } }

      it { is_expected.to be_falsey }
    end

    context 'with a number' do
      let(:config) { 5 }

      it { is_expected.to be_falsey }
    end
  end

  describe '.build_from' do
    subject { described_class.build_from('test', config) }

    let(:config) do
      {
        matrix: [
          { 'PROVIDER' => %w[aws], 'STACK' => %w[app1 app2] },
          { 'PROVIDER' => %w[ovh gcp], 'STACK' => %w[app] }
        ]
      }
    end

    it { expect(subject.size).to eq(4) }

    it 'has attributes' do
      expect(subject.map(&:attributes)).to match_array(
        [
          {
            name: 'test 1/4',
            instance: 1,
            parallel: { total: 4 },
            variables: {
              'PROVIDER' => 'aws',
              'STACK' => 'app1'
            }
          },
          {
            name: 'test 2/4',
            instance: 2,
            parallel: { total: 4 },
            variables: {
              'PROVIDER' => 'aws',
              'STACK' => 'app2'
            }
          },
          {
            name: 'test 3/4',
            instance: 3,
            parallel: { total: 4 },
            variables: {
              'PROVIDER' => 'ovh',
              'STACK' => 'app'
            }
          },
          {
            name: 'test 4/4',
            instance: 4,
            parallel: { total: 4 },
            variables: {
              'PROVIDER' => 'gcp',
              'STACK' => 'app'
            }
          }
        ]
      )
    end

    it 'has parallelized name' do
      expect(subject.map(&:name)).to match_array(
        ['test 1/4', 'test 2/4', 'test 3/4', 'test 4/4']
      )
    end

    it 'has details' do
      expect(subject.map(&:name_with_details)).to match_array(
        [
          'test (PROVIDER=aws; STACK=app1)',
          'test (PROVIDER=aws; STACK=app2)',
          'test (PROVIDER=gcp; STACK=app)',
          'test (PROVIDER=ovh; STACK=app)'
        ]
      )
    end
  end
end
