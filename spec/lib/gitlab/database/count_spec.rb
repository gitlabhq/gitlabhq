require 'spec_helper'

describe Gitlab::Database::Count do
  before do
    create_list(:project, 3)
    create(:identity)
  end

  let(:models) { [Project, Identity] }

  context '.approximate_counts' do
    context 'selecting strategies' do
      let(:strategies) { [double('s1', :enabled? => true), double('s2', :enabled? => false)] }

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
          double('s1', :enabled? => true, new: first_strategy),
          double('s2', :enabled? => true, new: second_strategy)
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

    xcontext 'with PostgreSQL', :postgresql do
      let(:reltuples_strategy) { double('reltuples_strategy', count: {}) }
      let(:exact_strategy) { double('exact_strategy', count: {}) }

      before do
        allow(Gitlab::Database::Count::ReltuplesCountStrategy).to receive(:new).with(models).and_return(reltuples_strategy)
      end

      describe 'when reltuples have not been updated' do
        it 'counts all models the normal way' do
          expect(Project).to receive(:count).and_call_original
          expect(Identity).to receive(:count).and_call_original
          expect(described_class.approximate_counts(models)).to eq({ Project => 3, Identity => 1 })
        end
      end

      describe 'no permission' do
        it 'falls back to standard query' do
          allow(ActiveRecord::Base).to receive(:transaction).and_raise(PG::InsufficientPrivilege)

          expect(Project).to receive(:count).and_call_original
          expect(Identity).to receive(:count).and_call_original
          expect(described_class.approximate_counts(models)).to eq({ Project => 3, Identity => 1 })
        end
      end

      describe 'when some reltuples have been updated' do
        it 'counts projects in the fast way' do
          expect(reltuples_strategy).to receive(:count).and_return({ Project => 3 })

          expect(Project).not_to receive(:count).and_call_original
          expect(Identity).to receive(:count).and_call_original
          expect(described_class.approximate_counts(models)).to eq({ Project => 3, Identity => 1 })
        end
      end

      # TODO: This covers two parts: reltuple strategy itself and the fallback
      # TODO: Add spec that covers strategy details for reltuple strategy
      describe 'when all reltuples have been updated' do
        #before do
          #ActiveRecord::Base.connection.execute('ANALYZE projects')
          #ActiveRecord::Base.connection.execute('ANALYZE identities')
        #end

        it 'counts models with the standard way' do
          allow(reltuples_strategy).to receive(:count).and_return({ Project => 3, Identity => 1 })
          expect(Project).not_to receive(:count)
          expect(Identity).not_to receive(:count)

          expect(described_class.approximate_counts(models)).to eq({ Project => 3, Identity => 1 })
        end
      end
    end
  end

  describe Gitlab::Database::Count::ExactCountStrategy do
    subject { described_class.new(models).count }

    describe '#count' do
      it 'counts all models' do
        models.each { |model| expect(model).to receive(:count).and_call_original }

        expect(subject).to eq({ Project => 3, Identity => 1 })
      end
    end

    describe '.enabled?' do
      it 'is enabled for PostgreSQL' do
        allow(Gitlab::Database).to receive(:postgresql?).and_return(true)

        expect(described_class.enabled?).to be_truthy
      end

      it 'is enabled for MySQL' do
        allow(Gitlab::Database).to receive(:postgresql?).and_return(false)

        expect(described_class.enabled?).to be_truthy
      end
    end
  end

  describe Gitlab::Database::Count::ReltuplesCountStrategy do
    subject { described_class.new(models).count }

    describe '#count' do
      context 'when reltuples is not up to date' do
        it 'returns an empty hash' do
          models.each { |model| expect(model).not_to receive(:count) }

          expect(subject).to eq({})
        end
      end
    end

    describe '.enabled?' do
      it 'is enabled for PostgreSQL' do
        allow(Gitlab::Database).to receive(:postgresql?).and_return(true)

        expect(described_class.enabled?).to be_truthy
      end

      it 'is disabled for MySQL' do
        allow(Gitlab::Database).to receive(:postgresql?).and_return(false)

        expect(described_class.enabled?).to be_falsey
      end
    end
  end
end
