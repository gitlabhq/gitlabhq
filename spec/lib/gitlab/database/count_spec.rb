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
      context 'when reltuples is up to date' do
        before do
          ActiveRecord::Base.connection.execute('ANALYZE projects')
          ActiveRecord::Base.connection.execute('ANALYZE identities')
        end

        it 'uses statistics to do the count' do
          models.each { |model| expect(model).not_to receive(:count) }

          expect(subject).to eq({ Project => 3, Identity => 1 })
        end
      end

      context 'insufficient permissions' do
        it 'returns an empty hash' do
          allow(ActiveRecord::Base).to receive(:transaction).and_raise(PG::InsufficientPrivilege)

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

  describe Gitlab::Database::Count::TablesampleCountStrategy do
    subject { strategy.count }
    let(:strategy) { described_class.new(models) }

    describe '#count' do
      let(:estimates) { { Project => threshold + 1, Identity => threshold - 1 } }
      let(:threshold) { Gitlab::Database::Count::TablesampleCountStrategy::EXACT_COUNT_THRESHOLD }

      before do
        allow(strategy).to receive(:size_estimates).with(check_statistics: false).and_return(estimates)
      end

      context 'for tables with an estimated small size' do
        it 'performs an exact count' do
          expect(Identity).to receive(:count).and_call_original

          expect(subject).to include({ Identity => 1 })
        end
      end

      context 'for tables with an estimated large size' do
        it 'performs a tablesample count' do
          expect(Project).not_to receive(:count)

          result = subject
          expect(result[Project]).to eq(3)
        end
      end

      context 'insufficient permissions' do
        it 'returns an empty hash' do
          allow(strategy).to receive(:size_estimates).and_raise(PG::InsufficientPrivilege)

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
