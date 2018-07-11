require 'spec_helper'

describe Gitlab::Database::Count do
  before do
    create_list(:project, 3)
    create(:identity)
  end

  let(:models) { [Project, Identity] }

  describe '.approximate_counts' do
    context 'with MySQL' do
      context 'when reltuples have not been updated' do
        it 'counts all models the normal way' do
          expect(Gitlab::Database).to receive(:postgresql?).and_return(false)

          expect(Project).to receive(:count).and_call_original
          expect(Identity).to receive(:count).and_call_original

          expect(described_class.approximate_counts(models)).to eq({ Project => 3, Identity => 1 })
        end
      end
    end

    context 'with PostgreSQL', :postgresql do
      describe 'when reltuples have not been updated' do
        it 'counts all models the normal way' do
          expect(described_class).to receive(:reltuples_from_recently_updated).with(%w(projects identities)).and_return({})

          expect(Project).to receive(:count).and_call_original
          expect(Identity).to receive(:count).and_call_original
          expect(described_class.approximate_counts(models)).to eq({ Project => 3, Identity => 1 })
        end
      end

      describe 'no permission' do
        it 'falls back to standard query' do
          allow(described_class).to receive(:postgresql_estimate_query).and_raise(PG::InsufficientPrivilege)

          expect(Project).to receive(:count).and_call_original
          expect(Identity).to receive(:count).and_call_original
          expect(described_class.approximate_counts(models)).to eq({ Project => 3, Identity => 1 })
        end
      end

      describe 'when some reltuples have been updated' do
        it 'counts projects in the fast way' do
          expect(described_class).to receive(:reltuples_from_recently_updated).with(%w(projects identities)).and_return({ 'projects' => 3 })

          expect(Project).not_to receive(:count).and_call_original
          expect(Identity).to receive(:count).and_call_original
          expect(described_class.approximate_counts(models)).to eq({ Project => 3, Identity => 1 })
        end
      end

      describe 'when all reltuples have been updated' do
        before do
          ActiveRecord::Base.connection.execute('ANALYZE projects')
          ActiveRecord::Base.connection.execute('ANALYZE identities')
        end

        it 'counts models with the standard way' do
          expect(Project).not_to receive(:count)
          expect(Identity).not_to receive(:count)

          expect(described_class.approximate_counts(models)).to eq({ Project => 3, Identity => 1 })
        end
      end
    end
  end
end
