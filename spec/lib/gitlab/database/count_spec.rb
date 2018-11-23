require 'spec_helper'

describe Gitlab::Database::Count do
  before do
    create_list(:project, 3)
    create(:identity)
  end

  let(:models) { [Project, Identity] }

  context '.approximate_counts' do
    context 'selecting strategies' do
      let(:strategies) { [double('s1', enabled?: true), double('s2', enabled?: false)] }

      it 'uses only enabled strategies' do
        expect(strategies[0]).to receive(:new).and_return(double('strategy1', count: {}))
        expect(strategies[1]).not_to receive(:new)

        described_class.approximate_counts(models, strategies: strategies)
      end
    end

    context 'fallbacks' do
      subject { described_class.approximate_counts(models, strategies: strategies) }

      let(:strategies) do
        [
          double('s1', enabled?: true, new: first_strategy),
          double('s2', enabled?: true, new: second_strategy)
        ]
      end

      let(:first_strategy) { double('first strategy', count: {}) }
      let(:second_strategy) { double('second strategy', count: {}) }

      it 'gets results from first strategy' do
        expect(strategies[0]).to receive(:new).with(models).and_return(first_strategy)
        expect(first_strategy).to receive(:count)

        subject
      end

      it 'gets more results from second strategy if some counts are missing' do
        expect(first_strategy).to receive(:count).and_return({ Project => 3 })
        expect(strategies[1]).to receive(:new).with([Identity]).and_return(second_strategy)
        expect(second_strategy).to receive(:count).and_return({ Identity => 1 })

        expect(subject).to eq({ Project => 3, Identity => 1 })
      end

      it 'does not get more results as soon as all counts are present' do
        expect(first_strategy).to receive(:count).and_return({ Project => 3, Identity => 1 })
        expect(strategies[1]).not_to receive(:new)

        subject
      end
    end
  end
end
