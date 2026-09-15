# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Capture::Tasks, feature_category: :database do
  # Reset singleton between tests
  before do
    described_class.instance.instance_variable_set(:@tasks, {})
  end

  describe 'a singleton' do
    it 'returns the same instance' do
      instance1 = described_class.instance
      instance2 = described_class.instance

      expect(instance1).to be(instance2)
    end

    it 'cannot be instantiated directly' do
      expect { described_class.new }.to raise_error(NoMethodError)
    end
  end

  describe 'contains Capture instances' do
    it 'automatically stores Capture instances when created' do
      capture_task = Gitlab::Database::Capture::Task.new(database_name: 'main')

      expect(described_class['main']).to eq(capture_task)
    end

    it 'stores captures for different databases' do
      main_capture_task = Gitlab::Database::Capture::Task.new(database_name: 'main')
      ci_capture_task = Gitlab::Database::Capture::Task.new(database_name: 'ci')

      expect(described_class['main']).to eq(main_capture_task)
      expect(described_class['ci']).to eq(ci_capture_task)
    end

    it 'overwrites existing captures when new ones are created with same database name' do
      first_capture_task = Gitlab::Database::Capture::Task.new(database_name: 'main')
      expect(described_class['main']).to eq(first_capture_task)

      second_capture_task = Gitlab::Database::Capture::Task.new(database_name: 'main')
      expect(described_class['main']).to eq(second_capture_task)
      expect(described_class['main']).not_to eq(first_capture_task)
    end

    it 'maintains object identity for auto-registered captures' do
      capture_task = Gitlab::Database::Capture::Task.new(database_name: 'main')
      retrieved = described_class['main']

      expect(retrieved).to be(capture_task) # Same object reference
    end
  end

  describe 'class method delegation' do
    it 'delegates [] to instance' do
      capture_task = Gitlab::Database::Capture::Task.new(database_name: 'main')
      expect(described_class['main']).to eq(capture_task)
    end

    it 'delegates []= to instance' do
      capture_task = Gitlab::Database::Capture::Task.new(database_name: 'ci')
      expect(described_class.instance['ci']).to eq(capture_task)
    end
  end
end
