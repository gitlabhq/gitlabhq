require 'spec_helper'

describe InternalId do
  let(:project) { create(:project) }
  let(:usage) { :issues }
  let(:issue) { build(:issue, project: project) }
  let(:scope) { :project }
  let(:init) { ->(s) { project.issues.size } }

  context 'validations' do
    it { is_expected.to validate_presence_of(:usage) }
    it { is_expected.to validate_presence_of(:project_id) }
  end

  describe '.generate_next' do
    context 'in the absence of a record' do
      subject { described_class.generate_next(issue, scope, usage, init) }

      it 'creates a record if not yet present' do
        expect { subject }.to change { described_class.count }.from(0).to(1)
      end

      it 'stores record attributes' do
        subject

        described_class.first.tap do |record|
          expect(record.project).to eq(project)
          expect(record.usage).to eq(usage.to_s)
        end
      end

      context 'with existing issues' do
        before do
          rand(10).times { create(:issue, project: project) }
          InternalId.delete_all
        end

        it 'calculates last_value values automatically' do
          expect(subject).to eq(project.issues.size + 1)
        end
      end
    end

    it 'generates a strictly monotone, gapless sequence' do
      seq = (0..rand(1000)).map do
        described_class.generate_next(issue, scope, usage, init)
      end
      normalized = seq.map { |i| i - seq.min }
      expect(normalized).to eq((0..seq.size - 1).to_a)
    end
  end

  describe '#increment_and_save!' do
    let(:id) { create(:internal_id) }
    subject { id.increment_and_save! }

    it 'returns incremented iid' do
      value = id.last_value
      expect(subject).to eq(value + 1)
    end

    it 'saves the record' do
      subject
      expect(id.changed?).to be_falsey
    end

    context 'with last_value=nil' do
      let(:id) { build(:internal_id, last_value: nil) }

      it 'returns 1' do
        expect(subject).to eq(1)
      end
    end
  end
end
