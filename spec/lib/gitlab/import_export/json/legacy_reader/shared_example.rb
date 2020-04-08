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
      let(:key) { 'labels' }

      subject { legacy_reader.consume_relation("project", key) }

      context 'key has not been consumed' do
        it 'returns an Enumerator' do
          expect(subject).to be_an_instance_of(Enumerator)
        end

        context 'value is nil' do
          before do
            expect(legacy_reader).to receive(:relations).and_return({ key => nil })
          end

          it 'yields nothing to the Enumerator' do
            expect(subject.to_a).to eq([])
          end
        end

        context 'value is an array' do
          before do
            expect(legacy_reader).to receive(:relations).and_return({ key => %w[label1 label2] })
          end

          it 'yields every relation value to the Enumerator' do
            expect(subject.to_a).to eq([['label1', 0], ['label2', 1]])
          end
        end

        context 'value is not array' do
          before do
            expect(legacy_reader).to receive(:relations).and_return({ key => 'non-array value' })
          end

          it 'yields the value with index 0 to the Enumerator' do
            expect(subject.to_a).to eq([['non-array value', 0]])
          end
        end
      end

      context 'key has been consumed' do
        before do
          legacy_reader.consume_relation("project", key).first
        end

        it 'yields nothing to the Enumerator' do
          expect(subject.to_a).to eq([])
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
