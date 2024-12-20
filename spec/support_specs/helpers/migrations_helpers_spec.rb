# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MigrationsHelpers, feature_category: :database do
  let(:helper_class) do
    Class.new.tap do |klass|
      klass.include described_class
      allow(klass).to receive(:metadata).and_return(metadata)
    end
  end

  let(:metadata) { {} }
  let(:helper) { helper_class.new }

  describe '#active_record_base' do
    it 'returns the main base model' do
      expect(helper.active_record_base).to eq(ActiveRecord::Base)
    end

    context 'ci database configured' do
      before do
        skip_if_multiple_databases_not_setup(:ci)
      end

      it 'returns the CI base model' do
        expect(helper.active_record_base(database: :ci)).to eq(Ci::ApplicationRecord)
      end
    end

    context 'ci database not configured' do
      before do
        skip_if_multiple_databases_are_setup(:ci)
      end

      it 'returns the CI base model with a connection to the main model' do
        model = helper.active_record_base(database: :ci)

        expect(model).to eq(Ci::ApplicationRecord)
        expect(model.connection_specification_name).to eq('ActiveRecord::Base')
      end
    end

    it 'raises ArgumentError for bad database argument' do
      expect { helper.active_record_base(database: :non_existent) }.to raise_error(ArgumentError)
    end
  end

  describe '#table' do
    it 'creates a class based on main base model' do
      klass = helper.table(:projects)
      expect(klass.connection_specification_name).to eq('ActiveRecord::Base')
    end

    context 'ci database configured' do
      before do
        skip_if_multiple_databases_not_setup(:ci)
      end

      it 'create a class based on the CI base model' do
        klass = helper.table(:p_ci_builds, database: :ci) { |model| model.primary_key = :id }
        expect(klass.connection_specification_name).to eq('Ci::ApplicationRecord')
      end
    end

    context 'ci database not configured' do
      before do
        skip_if_multiple_databases_are_setup(:ci)
      end

      it 'creates a class based on main base model' do
        klass = helper.table(:p_ci_builds, database: :ci) { |model| model.primary_key = :id }
        expect(klass.connection_specification_name).to eq('ActiveRecord::Base')
      end
    end
  end

  describe '#reset_column_information' do
    context 'with a regular ActiveRecord model class' do
      let(:klass) { Project }

      it 'calls reset_column_information' do
        expect(klass).to receive(:reset_column_information)

        helper.reset_column_information(klass)
      end
    end

    context 'with an anonymous class with table name defined' do
      let(:klass) do
        Class.new(ActiveRecord::Base) do
          self.table_name = :projects
        end
      end

      it 'calls reset_column_information' do
        expect(klass).to receive(:reset_column_information)

        helper.reset_column_information(klass)
      end
    end

    context 'with an anonymous class with no table name defined' do
      let(:klass) { Class.new(ActiveRecord::Base) }

      it 'does not call reset_column_information' do
        expect(klass).not_to receive(:reset_column_information)

        helper.reset_column_information(klass)
      end
    end
  end

  describe '#finalized_by_version' do
    let(:dictionary_entry) { nil }

    before do
      allow(helper).to receive(:described_class)
      allow(::Gitlab::Utils::BatchedBackgroundMigrationsDictionary).to(
        receive(:entry).and_return(dictionary_entry)
      )
    end

    context 'when no dictionary was found' do
      it { expect(helper.finalized_by_version).to be_nil }
    end

    context 'when finalized_by is a string' do
      let(:dictionary_entry) do
        instance_double(
          ::Gitlab::Utils::BatchedBackgroundMigrationsDictionary,
          finalized_by: '20240104155616'
        )
      end

      it { expect(helper.finalized_by_version).to eq(20240104155616) }
    end
  end
end
