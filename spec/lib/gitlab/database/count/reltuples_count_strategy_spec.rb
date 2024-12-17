# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Count::ReltuplesCountStrategy, feature_category: :database do
  before do
    create_list(:project, 3)
    create_list(:ci_instance_variable, 2)
  end

  subject { described_class.new(models).count }

  describe '#count' do
    let(:models) { [Project, Ci::InstanceVariable] }

    context 'when reltuples is up to date' do
      before do
        Project.connection.execute('ANALYZE projects')
        Ci::InstanceVariable.connection.execute('ANALYZE ci_instance_variables')
      end

      it 'uses statistics to do the count', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446141' do
        models.each { |model| expect(model).not_to receive(:count) }

        expect(subject).to eq({ Project => 3, Ci::InstanceVariable => 2 })
      end
    end

    context 'when models using single-type inheritance are used' do
      let(:models) { [Group, Namespace] }

      before do
        models.each do |model|
          model.connection.execute("ANALYZE #{model.table_name}")
        end
      end

      it 'returns nil counts for inherited tables' do
        models.each { |model| expect(model).not_to receive(:count) }

        # 3 Namespaces as parents for each Project and 3 ProjectNamespaces(for each Project)
        expect(subject).to eq({ Namespace => 6 })
      end
    end

    context 'insufficient permissions' do
      it 'returns an empty hash' do
        Gitlab::Database.database_base_models.each_value do |base_model|
          allow(base_model).to receive(:transaction).and_raise(PG::InsufficientPrivilege)
        end

        expect(subject).to eq({})
      end
    end
  end
end
