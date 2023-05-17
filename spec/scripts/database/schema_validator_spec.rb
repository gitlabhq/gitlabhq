# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../scripts/database/schema_validator'

RSpec.describe SchemaValidator, feature_category: :database do
  subject(:validator) { described_class.new }

  describe "#validate!" do
    before do
      allow(validator).to receive(:committed_migrations).and_return(committed_migrations)
      allow(validator).to receive(:run).and_return(schema_changes)
    end

    context 'when schema changes are introduced without migrations' do
      let(:committed_migrations) { [] }
      let(:schema_changes) { 'db/structure.sql' }

      it 'terminates the execution' do
        expect { validator.validate! }.to raise_error(SystemExit)
      end
    end

    context 'when schema changes are introduced with migrations' do
      let(:committed_migrations) { ['20211006103122_my_migration.rb'] }
      let(:schema_changes) { 'db/structure.sql' }
      let(:command) { 'git diff db/structure.sql -- db/structure.sql' }
      let(:base_message) { 'db/structure.sql was changed, and no migrations were added' }

      before do
        allow(validator).to receive(:die)
      end

      it 'skips schema validations' do
        expect(validator.validate!).to be_nil
      end
    end

    context 'when skipping validations through ENV variable' do
      let(:committed_migrations) { [] }
      let(:schema_changes) { 'db/structure.sql' }

      before do
        stub_env('ALLOW_SCHEMA_CHANGES', true)
      end

      it 'skips schema validations' do
        expect(validator.validate!).to be_nil
      end
    end

    context 'when skipping validations through commit message' do
      let(:committed_migrations) { [] }
      let(:schema_changes) { 'db/structure.sql' }
      let(:commit_message) { "Changes db/strucure.sql file\nskip-db-structure-check" }

      before do
        allow(validator).to receive(:run).and_return(commit_message)
      end

      it 'skips schema validations' do
        expect(validator.validate!).to be_nil
      end
    end
  end
end
