require 'spec_helper'

describe Gitlab::Database::Count::ReltuplesCountStrategy do
  before do
    create_list(:project, 3)
    create(:identity)
  end

  let(:models) { [Project, Identity] }
  subject { described_class.new(models).count }

  describe '#count', :postgresql do
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
