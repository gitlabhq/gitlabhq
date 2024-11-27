# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Count do
  before do
    create_list(:project, 3)
    create(:identity)
  end

  let(:models) { [::Project, ::Identity] }

  describe '.approximate_counts' do
    context 'fallbacks' do
      subject { described_class.approximate_counts(models, strategies: strategies) }

      let(:strategies) do
        [
          double('s1', new: first_strategy),
          double('s2', new: second_strategy)
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
        expect(first_strategy).to receive(:count).and_return({ ::Project => 3 })
        expect(strategies[1]).to receive(:new).with([::Identity]).and_return(second_strategy)
        expect(second_strategy).to receive(:count).and_return({ ::Identity => 1 })

        expect(subject).to eq({ ::Project => 3, ::Identity => 1 })
      end

      it 'does not get more results as soon as all counts are present' do
        expect(first_strategy).to receive(:count).and_return({ ::Project => 3, ::Identity => 1 })
        expect(strategies[1]).not_to receive(:new)

        subject
      end
    end

    context 'default strategies' do
      subject { described_class.approximate_counts(models) }

      context 'with a read-only database' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        end

        it 'only uses the ExactCountStrategy' do
          allow_next_instance_of(Gitlab::Database::Count::TablesampleCountStrategy) do |instance|
            expect(instance).not_to receive(:count)
          end
          allow_next_instance_of(Gitlab::Database::Count::ReltuplesCountStrategy) do |instance|
            expect(instance).not_to receive(:count)
          end
          expect_next_instance_of(Gitlab::Database::Count::ExactCountStrategy) do |instance|
            expect(instance).to receive(:count).and_return({})
          end

          subject
        end
      end

      context 'with a read-write database' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(false)
        end

        it 'uses the available strategies' do
          [
            Gitlab::Database::Count::TablesampleCountStrategy,
            Gitlab::Database::Count::ReltuplesCountStrategy,
            Gitlab::Database::Count::ExactCountStrategy
          ].each do |strategy_klass|
            expect_next_instance_of(strategy_klass) do |instance|
              expect(instance).to receive(:count).and_return({})
            end
          end

          subject
        end
      end
    end
  end
end
