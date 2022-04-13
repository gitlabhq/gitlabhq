# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migration do
  describe '.[]' do
    context 'version: 1.0' do
      subject { described_class[1.0] }

      it 'inherits from ActiveRecord::Migration[6.1]' do
        expect(subject.superclass).to eq(ActiveRecord::Migration[6.1])
      end

      it 'includes migration helpers version 2' do
        expect(subject.included_modules).to include(Gitlab::Database::MigrationHelpers::V2)
      end

      it 'includes LockRetriesConcern' do
        expect(subject.included_modules).to include(Gitlab::Database::Migration::LockRetriesConcern)
      end
    end

    context 'unknown version' do
      it 'raises an error' do
        expect { described_class[0] }.to raise_error(ArgumentError, /Unknown migration version/)
      end
    end
  end

  describe '.current_version' do
    it 'includes current ActiveRecord migration class' do
      # This breaks upon Rails upgrade. In that case, we'll add a new version in Gitlab::Database::Migration::MIGRATION_CLASSES,
      # bump .current_version and leave existing migrations and already defined versions of Gitlab::Database::Migration
      # untouched.
      expect(described_class[described_class.current_version]).to be < ActiveRecord::Migration::Current
    end
  end

  describe Gitlab::Database::Migration::LockRetriesConcern do
    subject { class_def.new }

    context 'when not explicitly called' do
      let(:class_def) do
        Class.new do
          include Gitlab::Database::Migration::LockRetriesConcern
        end
      end

      it 'does not disable lock retries by default' do
        expect(subject.enable_lock_retries?).not_to be_truthy
      end
    end

    context 'when explicitly disabled' do
      let(:class_def) do
        Class.new do
          include Gitlab::Database::Migration::LockRetriesConcern

          enable_lock_retries!
        end
      end

      it 'does not disable lock retries by default' do
        expect(subject.enable_lock_retries?).to be_truthy
      end
    end
  end
end
