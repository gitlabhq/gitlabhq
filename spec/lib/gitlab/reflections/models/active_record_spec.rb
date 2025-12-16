# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Reflections::Models::ActiveRecord, feature_category: :database do
  let(:instance) { described_class.instance }

  describe '#model_name_to_table_name' do
    it 'returns the table name for a valid model' do
      expect(instance.model_name_to_table_name('User')).to eq('users')
    end

    it 'returns nil for non-existent model' do
      expect(instance.model_name_to_table_name('NonExistentModel')).to be_nil
    end

    it 'returns nil for invalid model name' do
      expect(instance.model_name_to_table_name('InvalidModelName123')).to be_nil
    end
  end

  describe '#table_name_to_model_names' do
    it 'returns array of model names for a given table' do
      model_names = instance.table_name_to_model_names('users')
      expect(model_names).to be_an(Array)
      expect(model_names).to include('User')
    end

    it 'handles multiple models sharing the same table' do
      model_names = instance.table_name_to_model_names('namespaces')
      expect(model_names).to be_an(Array)
      expect(model_names).to include('Namespace', 'Group')
    end

    it 'returns empty array for non-existent table' do
      model_names = instance.table_name_to_model_names('non_existent_table')
      expect(model_names).to eq([])
    end

    it 'returns empty array when table has no classes defined' do
      # Mock a dictionary entry without classes
      entry = instance_double(Gitlab::Database::Dictionary::Entry, classes: nil)
      allow(Gitlab::Database::Dictionary).to receive(:any_entry).with('some_table').and_return(entry)

      model_names = instance.table_name_to_model_names('some_table')
      expect(model_names).to eq([])
    end

    it 'returns empty array when dictionary entry is not found' do
      allow(Gitlab::Database::Dictionary).to receive(:any_entry).with('missing_table').and_return(nil)

      model_names = instance.table_name_to_model_names('missing_table')
      expect(model_names).to eq([])
    end
  end

  describe '#models' do
    it 'returns an array of model classes' do
      expect(instance.models).to be_an(Array)
      expect(instance.models).to all(be < ApplicationRecord)
    end

    it 'caches the result' do
      # First call
      models1 = instance.models
      # Second call should return the same object
      models2 = instance.models
      expect(models1).to be(models2)
    end
  end

  describe 'singleton behavior' do
    it 'returns the same instance' do
      instance1 = described_class.instance
      instance2 = described_class.instance

      expect(instance1).to be(instance2)
    end
  end
end
