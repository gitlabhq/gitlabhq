# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::Transformers::Pipeline, feature_category: :database do
  # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
  let(:transformer1) { double('Transformer1') }
  let(:transformer2) { double('Transformer2') }
  let(:transformer3) { double('Transformer3') }
  # rubocop:enable RSpec/VerifiedDoubles

  describe '#initialize' do
    it 'accepts multiple transformers' do
      pipeline = described_class.new(transformer1, transformer2, transformer3)

      expect(pipeline.instance_variable_get(:@transformers)).to match_array([transformer1, transformer2, transformer3])
    end

    it 'accepts a single transformer' do
      pipeline = described_class.new(transformer1)

      expect(pipeline.instance_variable_get(:@transformers)).to eq([transformer1])
    end

    it 'accepts no transformers' do
      pipeline = described_class.new

      expect(pipeline.instance_variable_get(:@transformers)).to eq([])
    end
  end

  describe '#execute' do
    let(:input_data) { %w[initial data] }

    context 'with no transformers' do
      it 'returns the input unchanged' do
        pipeline = described_class.new

        result = pipeline.execute(input_data)

        expect(result).to eq(input_data)
      end
    end

    context 'with a single transformer' do
      it 'applies the transformer to the input' do
        transformed_data = %w[transformed data]
        expect(transformer1).to receive(:call).with(input_data).and_return(transformed_data)

        pipeline = described_class.new(transformer1)
        result = pipeline.execute(input_data)

        expect(result).to eq(transformed_data)
      end
    end

    context 'with multiple transformers' do
      it 'applies transformers in sequence, passing output of one as input to the next' do
        step1_output = %w[step1 output]
        step2_output = %w[step2 output]
        final_output = %w[final output]

        expect(transformer1).to receive(:call).with(input_data).and_return(step1_output)
        expect(transformer2).to receive(:call).with(step1_output).and_return(step2_output)
        expect(transformer3).to receive(:call).with(step2_output).and_return(final_output)

        pipeline = described_class.new(transformer1, transformer2, transformer3)
        result = pipeline.execute(input_data)

        expect(result).to eq(final_output)
      end
    end

    context 'with real transformer classes' do
      let(:valid_relationship) do
        Gitlab::Reflections::Relationships::Relationship.new(
          parent_table: 'users',
          child_table: 'posts',
          foreign_key: 'user_id',
          primary_key: 'id',
          relationship_type: 'one_to_many'
        )
      end

      let(:invalid_relationship) do
        Gitlab::Reflections::Relationships::Relationship.new(
          parent_table: 'users',
          child_table: nil,
          foreign_key: 'user_id'
        )
      end

      let(:duplicate_relationship) do
        Gitlab::Reflections::Relationships::Relationship.new(
          parent_table: 'users',
          child_table: 'posts',
          foreign_key: 'user_id',
          primary_key: 'id',
          relationship_type: 'one_to_many'
        )
      end

      it 'integrates deduplicate and validate transformers' do
        input_relationships = [valid_relationship, invalid_relationship, duplicate_relationship]

        pipeline = described_class.new(
          Gitlab::Reflections::Relationships::Transformers::Deduplicate,
          Gitlab::Reflections::Relationships::Transformers::Validate
        )

        result = pipeline.execute(input_relationships)

        # Should deduplicate first (removing duplicate_relationship), then validate (removing invalid_relationship)
        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
        expect(result.first).to be_a(Gitlab::Reflections::Relationships::Relationship)
        expect(result.first.parent_table).to eq('users')
        expect(result.first.child_table).to eq('posts')
        expect(result.first.foreign_key).to eq('user_id')
      end
    end

    context 'with transformer that returns different data type' do
      it 'handles type transformations between steps' do
        # First transformer converts array to hash
        expect(transformer1).to receive(:call).with(%w[a b]).and_return({ data: %w[a b] })
        # Second transformer processes the hash
        expect(transformer2).to receive(:call).with({ data: %w[a b] }).and_return({ processed: true })

        pipeline = described_class.new(transformer1, transformer2)
        result = pipeline.execute(%w[a b])

        expect(result).to eq({ processed: true })
      end
    end

    context 'when a transformer raises an error' do
      it 'propagates the error' do
        expect(transformer1).to receive(:call).with(input_data).and_raise(StandardError, 'Transformer error')

        pipeline = described_class.new(transformer1, transformer2)

        expect { pipeline.execute(input_data) }.to raise_error(StandardError, 'Transformer error')
      end

      it 'does not call subsequent transformers when an error occurs' do
        expect(transformer1).to receive(:call).with(input_data).and_raise(StandardError, 'Transformer error')
        expect(transformer2).not_to receive(:call)

        pipeline = described_class.new(transformer1, transformer2)

        expect { pipeline.execute(input_data) }.to raise_error(StandardError, 'Transformer error')
      end
    end
  end
end
