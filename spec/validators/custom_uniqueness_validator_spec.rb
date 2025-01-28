# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomUniquenessValidator, feature_category: :shared do
  before_all do
    ApplicationRecord.connection.execute(
      <<~SQL
        CREATE TABLE IF NOT EXISTS _test_custom_uniqueness (
          id smallint PRIMARY KEY,
          name VARCHAR(500),
          number smallint,
          second_number smallint
        );
      SQL
    )
  end

  let_it_be(:existing_record_name) { 'Some Name' }

  shared_examples 'custom uniqueness validator' do
    subject { test_model.new(**new_record_attributes) }

    before do
      test_model.create!(id: 1, **existing_record_attributes)
    end

    it 'uses TRIM(BOTH FROM lower()) to validate' do
      new_record = test_model.new(**valid_new_attributes)

      expect do
        new_record.valid?
      end.to make_queries_matching(
        /TRIM\(BOTH FROM lower\(_test_custom_uniqueness.name\)\) = TRIM\(BOTH FROM lower\('/
      )
    end

    it 'adds an error to the record' do
      new_record = test_model.new(**existing_record_attributes)

      new_record.valid?

      expect(new_record.errors.full_messages).to include('Name has already been taken')
    end

    context 'when new record has leading whitespace' do
      let(:new_record_name) { " #{existing_record_name}" }

      it { is_expected.to be_invalid }
    end

    context 'when new record has trailing whitespace' do
      let(:new_record_name) { "#{existing_record_name} " }

      it { is_expected.to be_invalid }
    end

    context 'when new record does not match casing' do
      let(:new_record_name) { existing_record_name.upcase }

      it { is_expected.to be_invalid }
    end

    context 'when new record name does not match' do
      let(:new_record_name) { "#{existing_record_name} something else" }

      it { is_expected.to be_valid }
    end

    context 'when updating a record' do
      let(:existing_record) { test_model.first }

      subject(:updated) { existing_record.update(**new_record_attributes) } # rubocop:disable Rails/SaveBang -- Checking the return value in specs

      context 'when new value is exactly the same' do
        let(:new_record_name) { existing_record_name }

        it { is_expected.to be_truthy }
      end

      context 'when new value is the same in a different casing' do
        let(:new_record_name) { existing_record_name.upcase }

        it { is_expected.to be_truthy }

        it 'does update the record to the new casing' do
          expect do
            updated
          end.to change { existing_record.reload.name }.from(existing_record_name).to(existing_record_name.upcase)
        end
      end
    end
  end

  context 'when validation is not scoped to another column' do
    let_it_be(:test_model) do
      Class.new(ApplicationRecord) do
        self.table_name = :_test_custom_uniqueness

        def self.name
          'TestCustomUniqueness'
        end

        validates :name, custom_uniqueness: { unique_sql: 'TRIM(BOTH FROM lower(?))' }
      end
    end

    it_behaves_like 'custom uniqueness validator' do
      let(:existing_record_attributes) { { name: existing_record_name } }
      let(:valid_new_attributes) { { name: "#{existing_record_name} something else" } }
      let(:new_record_attributes) { { name: new_record_name } }
    end
  end

  context 'when validation is scoped to another column' do
    let_it_be(:test_model) do
      Class.new(ApplicationRecord) do
        self.table_name = :_test_custom_uniqueness

        def self.name
          'TestCustomUniqueness'
        end

        validates :name, custom_uniqueness: { unique_sql: 'TRIM(BOTH FROM lower(?))', scope: :number }
      end
    end

    it_behaves_like 'custom uniqueness validator' do
      let(:existing_record_attributes) { { name: existing_record_name, number: 1 } }
      let(:valid_new_attributes) { { name: "#{existing_record_name} something else", number: 2 } }
      let(:new_record_attributes) { { name: new_record_name, number: 1 } }
    end

    context 'when name matches but scope value does not' do
      it 'does not invalidate the record' do
        test_model.create!(id: 1, name: existing_record_name, number: 1)
        new_record = test_model.new(name: existing_record_name, number: 2)

        expect(new_record).to be_valid
      end
    end

    context 'when name and scope value matches an existing record' do
      it 'adds an error to the record' do
        test_model.create!(id: 1, name: existing_record_name, number: 1)
        new_record = test_model.new(name: existing_record_name, number: 1)

        new_record.valid?

        expect(new_record.errors.full_messages).to include('Name has already been taken')
      end

      context 'when name and scope value matches an existing record' do
        it 'adds an error to the record' do
          test_model.create!(id: 1, name: existing_record_name, number: 1)
          new_record = test_model.new(name: existing_record_name, number: 1)

          new_record.valid?

          expect(new_record.errors.full_messages).to include('Name has already been taken')
        end
      end

      context 'when updating an existing record' do
        before_all do
          test_model.create!(id: 1, name: existing_record_name, number: 1)
        end

        context 'when changing the attribute value' do
          it 'adds an error to the record' do
            record = test_model.create!(id: 2, name: "#{existing_record_name} different", number: 1)
            record.name = existing_record_name

            expect(record).to be_invalid
          end
        end

        context 'when changing the scope value' do
          it 'adds an error to the record' do
            record = test_model.create!(id: 2, name: existing_record_name, number: 2)
            record.number = 1

            expect(record).to be_invalid
          end
        end

        context 'when making valid changes to the attribute and scope values' do
          it 'does not invalidate the record' do
            record = test_model.create!(id: 2, name: "#{existing_record_name} different", number: 1)
            record.name = existing_record_name
            record.number = 2

            expect(record).to be_valid
          end
        end

        context 'when not changing the validated attributes or scoped values' do
          it 'does not issue queries to the DB' do
            record = test_model.create!(id: 2, name: "#{existing_record_name} different", number: 1)
            record.id = 100

            expect do
              record.valid?
            end.not_to make_queries

            expect(record).to be_valid
          end
        end
      end
    end
  end

  context 'when validation is scoped to multiple columns' do
    let_it_be(:test_model) do
      Class.new(ApplicationRecord) do
        self.table_name = :_test_custom_uniqueness

        def self.name
          'TestCustomUniqueness'
        end

        validates :name, custom_uniqueness: { unique_sql: 'TRIM(BOTH FROM lower(?))', scope: [:number, :second_number] }
      end
    end

    it_behaves_like 'custom uniqueness validator' do
      let(:existing_record_attributes) { { name: existing_record_name, number: 1, second_number: 101 } }
      let(:valid_new_attributes) { { name: "#{existing_record_name} something else", number: 2, second_number: 102 } }
      let(:new_record_attributes) { { name: new_record_name, number: 1, second_number: 101 } }
    end

    context 'when name matches but scope value does not' do
      it 'does not invalidate the record' do
        test_model.create!(id: 1, name: existing_record_name, number: 1, second_number: 101)
        new_record = test_model.new(name: existing_record_name, number: 1, second_number: 102)

        expect(new_record).to be_valid
      end
    end

    context 'when name and scope values matches an existing record' do
      it 'adds an error to the record' do
        test_model.create!(id: 1, name: existing_record_name, number: 1, second_number: 101)
        new_record = test_model.new(name: existing_record_name, number: 1, second_number: 101)

        new_record.valid?

        expect(new_record.errors.full_messages).to include('Name has already been taken')
      end
    end
  end

  context 'when validation definition is missing the `unique_sql key`' do
    it 'raises an ArgumentError' do
      expect do
        Class.new(ApplicationRecord) do
          self.table_name = :_test_custom_uniqueness

          def self.name
            'TestCustomUniqueness'
          end

          validates :name, custom_uniqueness: true
        end
      end.to raise_error(ArgumentError, '`unique_sql` option must be provided to the `custom_uniqueness` validator')
    end
  end
end
