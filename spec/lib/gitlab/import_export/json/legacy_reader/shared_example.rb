# frozen_string_literal: true

RSpec.shared_examples 'import/export json legacy reader' do
  let(:relation_names) { [] }

  let(:legacy_reader) do
    described_class.new(
      data,
      relation_names: relation_names,
      allowed_path: "project")
  end

  describe '#consume_attributes' do
    context 'when valid path is passed' do
      subject { legacy_reader.consume_attributes("project") }

      context 'no excluded attributes' do
        let(:excluded_attributes) { [] }
        let(:relation_names) { [] }

        it 'returns the whole tree from parsed JSON' do
          expect(subject).to eq(json_data)
        end
      end

      context 'some attributes are excluded' do
        let(:relation_names) { %w[milestones labels] }

        it 'returns hash without excluded attributes and relations' do
          expect(subject).not_to include('milestones', 'labels')
        end
      end
    end

    context 'when invalid path is passed' do
      it 'raises an exception' do
        expect { legacy_reader.consume_attributes("invalid-path") }
          .to raise_error(ArgumentError)
      end
    end
  end

  describe '#consume_relation' do
    context 'when valid path is passed' do
      let(:key) { 'description' }

      context 'block not given' do
        it 'returns value of the key' do
          expect(legacy_reader).to receive(:relations).and_return({ key => 'test value' })
          expect(legacy_reader.consume_relation("project", key)).to eq('test value')
        end
      end

      context 'key has been consumed' do
        before do
          legacy_reader.consume_relation("project", key)
        end

        it 'does not yield' do
          expect do |blk|
            legacy_reader.consume_relation("project", key, &blk)
          end.not_to yield_control
        end
      end

      context 'value is nil' do
        before do
          expect(legacy_reader).to receive(:relations).and_return({ key => nil })
        end

        it 'does not yield' do
          expect do |blk|
            legacy_reader.consume_relation("project", key, &blk)
          end.not_to yield_control
        end
      end

      context 'value is not array' do
        before do
          expect(legacy_reader).to receive(:relations).and_return({ key => 'value' })
        end

        it 'yield the value with index 0' do
          expect do |blk|
            legacy_reader.consume_relation("project", key, &blk)
          end.to yield_with_args('value', 0)
        end
      end

      context 'value is an array' do
        before do
          expect(legacy_reader).to receive(:relations).and_return({ key => %w[item1 item2 item3] })
        end

        it 'yield each array element with index' do
          expect do |blk|
            legacy_reader.consume_relation("project", key, &blk)
          end.to yield_successive_args(['item1', 0], ['item2', 1], ['item3', 2])
        end
      end
    end

    context 'when invalid path is passed' do
      it 'raises an exception' do
        expect { legacy_reader.consume_relation("invalid") }
          .to raise_error(ArgumentError)
      end
    end
  end
end
