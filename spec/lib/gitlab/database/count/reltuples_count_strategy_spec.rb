# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Count::ReltuplesCountStrategy do
  before do
    create_list(:project, 3)
    create(:identity)
  end

  subject { described_class.new(models).count }

  describe '#count' do
    let(:models) { [Project, Identity] }

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

    context 'when models using single-type inheritance are used' do
      let(:models) { [Group, Integrations::BaseCi, Namespace] }

      before do
        models.each do |model|
          ActiveRecord::Base.connection.execute("ANALYZE #{model.table_name}")
        end
      end

      it 'returns nil counts for inherited tables' do
        models.each { |model| expect(model).not_to receive(:count) }

        expect(subject).to eq({ Namespace => 3 })
      end
    end

    context 'insufficient permissions' do
      it 'returns an empty hash' do
        allow(ActiveRecord::Base).to receive(:transaction).and_raise(PG::InsufficientPrivilege)

        expect(subject).to eq({})
      end
    end
  end
end
