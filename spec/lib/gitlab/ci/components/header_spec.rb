# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Components::Header, feature_category: :pipeline_composition do
  subject { described_class.new(spec) }

  context 'when spec is valid' do
    let(:spec) do
      {
        spec: {
          inputs: {
            website: nil,
            run: {
              options: %w[opt1 opt2]
            }
          }
        }
      }
    end

    it 'fabricates a spec from valid data' do
      expect(subject).not_to be_empty
    end

    describe '#inputs' do
      it 'fabricates input data' do
        input = subject.inputs({ website: 'https//gitlab.com', run: 'opt1' })

        expect(input.count).to eq 2
      end
    end

    describe '#context' do
      it 'fabricates interpolation context' do
        ctx = subject.context({ website: 'https//gitlab.com', run: 'opt1' })

        expect(ctx).to be_valid
      end
    end
  end

  context 'when spec is empty' do
    let(:spec) { { spec: {} } }

    it 'returns an empty header' do
      expect(subject).to be_empty
    end
  end
end
