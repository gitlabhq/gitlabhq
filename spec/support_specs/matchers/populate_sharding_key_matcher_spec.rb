# frozen_string_literal: true

require 'spec_helper'
require 'rspec/matchers/fail_matchers'

RSpec.describe 'populate_sharding_key matcher', feature_category: :database do
  include RSpec::Matchers::FailMatchers

  let(:model_class) do
    Class.new(ApplicationRecord) do
      include PopulatesShardingKey
      self.table_name = 'users'

      attr_accessor :sharding_source, :foo
    end
  end

  let(:model) { model_class.new }

  shared_examples 'supports .with chain' do
    it 'passes when model is populated with provided value' do
      expect(model).to populate_sharding_key(:role).with(1)
    end

    it 'fails when model is not populated with provided value' do
      expect do
        expect(model).to populate_sharding_key(:role).with(2)
      end.to fail_with(/expected .* to populate role attribute but it didn't/)
    end

    it 'fails when model has value already assigned' do
      model.role = 2
      expect do
        expect(model).to populate_sharding_key(:role).with(1)
      end.to fail_with(/expected .* to populate role attribute but it didn't/)
    end
  end

  describe 'for definition with block' do
    let(:model_class) do
      super().tap do |klass|
        klass.populate_sharding_key(:role) { 1 }
      end
    end

    it_behaves_like 'supports .with chain'
  end

  describe 'for definition with source' do
    let(:model_class) do
      super().tap do |klass|
        klass.populate_sharding_key(:role, source: :sharding_source)
      end
    end

    let(:model) { model_class.new(sharding_source: double(role: 1)) } # rubocop:disable RSpec/VerifiedDoubles -- sharding_source can be anything so nothing to verify.

    it_behaves_like 'supports .with chain'

    context 'with .from chain' do
      it 'passes when model is populated from provided association' do
        expect(model).to populate_sharding_key(:role).from(:sharding_source)
      end

      it 'fails when model is not populated from provided association' do
        expect do
          expect(model).to populate_sharding_key(:role).from(:foo)
        end.to fail_with(/expected .* to populate role attribute but it didn't/)
      end

      it 'fails when model has value already assigned' do
        model.role = 2
        expect do
          expect(model).to populate_sharding_key(:role).from(:sharding_source)
        end.to fail_with(/expected .* to populate role attribute but it didn't/)
      end
    end
  end

  describe 'for definition with source and field' do
    let(:model_class) do
      super().tap do |klass|
        klass.populate_sharding_key(:role, source: :sharding_source, field: :bar)
      end
    end

    let(:model) { model_class.new(sharding_source: double(bar: 1, role: 2)) } # rubocop:disable RSpec/VerifiedDoubles -- sharding_source can be anything so nothing to verify.

    it_behaves_like 'supports .with chain'

    context 'with .from chain' do
      it 'passes when model is populated from provided association and field' do
        expect(model).to populate_sharding_key(:role).from(:sharding_source, :bar)
      end

      it 'fails when model is not populated from provided association' do
        expect do
          expect(model).to populate_sharding_key(:role).from(:sharding_source, :role)
        end.to fail_with(/expected .* to populate role attribute but it didn't/)
      end

      it 'fails when called without custom field' do
        expect do
          expect(model).to populate_sharding_key(:role).from(:sharding_source)
        end.to fail_with(/expected .* to populate role attribute but it didn't/)
      end

      it 'fails when model has value already assigned' do
        model.role = 2
        expect do
          expect(model).to populate_sharding_key(:role).from(:sharding_source, :bar)
        end.to fail_with(/expected .* to populate role attribute but it didn't/)
      end
    end
  end

  describe 'negation' do
    let(:model_class) do
      super().tap do |klass|
        klass.populate_sharding_key(:role) { 1 }
      end
    end

    it 'fails with negation not supported message' do
      expect do
        expect(model).not_to populate_sharding_key(:role).with(1)
      end.to raise_error("Negation is not supported for the populate_sharding_key matcher")
    end
  end
end
