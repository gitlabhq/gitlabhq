# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InternalId do
  let(:project) { create(:project) }
  let(:usage) { :issues }
  let(:issue) { build(:issue, project: project) }
  let(:id_subject) { issue }
  let(:scope) { { namespace: project.project_namespace } }
  let(:init) { ->(issue, scope) { issue&.project&.issues&.size || Issue.where(**scope).count } }

  it_behaves_like 'having unique enum values'

  context 'validations' do
    it { is_expected.to validate_presence_of(:usage) }
  end

  describe '.flush_records!' do
    subject { described_class.flush_records!(namespace: project.project_namespace) }

    let(:another_project) { create(:project) }

    before do
      create_list(:issue, 2, project: project)
      create_list(:issue, 2, project: another_project)
    end

    it 'deletes all records for the given project' do
      expect { subject }.to change { described_class.where(namespace: project.project_namespace).count }.from(1).to(0)
    end

    it 'retains records for other projects' do
      expect { subject }.not_to change { described_class.where(namespace: another_project.project_namespace).count }
    end

    it 'does not allow an empty filter' do
      expect { described_class.flush_records!({}) }.to raise_error(/filter cannot be empty/)
    end
  end

  describe '.generate_next' do
    subject { described_class.generate_next(id_subject, scope, usage, init) }

    context 'in the absence of a record' do
      it 'creates a record if not yet present' do
        expect { subject }.to change { described_class.count }.from(0).to(1)
      end

      it 'stores record attributes' do
        subject

        described_class.first.tap do |record|
          expect(record.namespace).to eq(project.project_namespace)
          expect(record.usage).to eq(usage.to_s)
        end
      end

      context 'with existing issues' do
        before do
          create_list(:issue, 2, project: project)
          described_class.delete_all
        end

        it 'calculates last_value values automatically' do
          expect(subject).to eq(project.issues.size + 1)
        end
      end
    end

    it 'generates a strictly monotone, gapless sequence' do
      seq = Array.new(10).map do
        described_class.generate_next(issue, scope, usage, init)
      end
      normalized = seq.map { |i| i - seq.min }

      expect(normalized).to eq((0..seq.size - 1).to_a)
    end

    context 'there are no instances to pass in' do
      let(:id_subject) { Issue }

      it 'accepts classes instead' do
        expect(subject).to eq(1)
      end
    end

    context 'when executed outside of transaction' do
      it 'increments counter with in_transaction: "false"' do
        allow(ApplicationRecord.connection).to receive(:transaction_open?) { false }

        expect(described_class.internal_id_transactions_total).to receive(:increment)
          .with(operation: :generate, usage: 'issues', in_transaction: 'false').and_call_original

        subject
      end
    end

    context 'when executed within transaction' do
      it 'increments counter with in_transaction: "true"' do
        expect(described_class.internal_id_transactions_total).to receive(:increment)
          .with(operation: :generate, usage: 'issues', in_transaction: 'true').and_call_original

        InternalId.transaction { subject }
      end
    end
  end

  describe '.reset' do
    subject { described_class.reset(issue, scope, usage, value) }

    context 'in the absence of a record' do
      let(:value) { 2 }

      it 'does not revert back the value' do
        expect { subject }.not_to change { described_class.count }
        expect(subject).to be_falsey
      end
    end

    context 'when valid iid is used to reset' do
      let!(:value) { generate_next }

      context 'and iid is a latest one' do
        it 'does rewind and next generated value is the same' do
          expect(subject).to be_truthy
          expect(generate_next).to eq(value)
        end
      end

      context 'and iid is not a latest one' do
        it 'does not rewind' do
          generate_next

          expect(subject).to be_falsey
          expect(generate_next).to be > value
        end
      end

      def generate_next
        described_class.generate_next(issue, scope, usage, init)
      end
    end

    context 'when executed outside of transaction' do
      let(:value) { 2 }

      it 'increments counter with in_transaction: "false"' do
        allow(ApplicationRecord.connection).to receive(:transaction_open?) { false }

        expect(described_class.internal_id_transactions_total).to receive(:increment)
          .with(operation: :reset, usage: 'issues', in_transaction: 'false').and_call_original

        subject
      end
    end

    context 'when executed within transaction' do
      let(:value) { 2 }

      it 'increments counter with in_transaction: "true"' do
        expect(described_class.internal_id_transactions_total).to receive(:increment)
          .with(operation: :reset, usage: 'issues', in_transaction: 'true').and_call_original

        InternalId.transaction { subject }
      end
    end
  end

  describe '.track_greatest' do
    let(:value) { 9001 }

    subject { described_class.track_greatest(id_subject, scope, usage, value, init) }

    context 'in the absence of a record' do
      it 'creates a record if not yet present' do
        expect { subject }.to change { described_class.count }.from(0).to(1)
      end
    end

    it 'stores record attributes' do
      subject

      described_class.first.tap do |record|
        expect(record.namespace).to eq(project.project_namespace)
        expect(record.usage).to eq(usage.to_s)
        expect(record.last_value).to eq(value)
      end
    end

    context 'with existing issues' do
      before do
        create(:issue, project: project)
        described_class.delete_all
      end

      it 'still returns the last value to that of the given value' do
        expect(subject).to eq(value)
      end
    end

    context 'when value is less than the current last_value' do
      it 'returns the current last_value' do
        described_class.create!(**scope, usage: usage, last_value: 10_001)

        expect(subject).to eq 10_001
      end
    end

    context 'there are no instances to pass in' do
      let(:id_subject) { Issue }

      it 'accepts classes instead' do
        expect(subject).to eq(value)
      end
    end

    context 'when executed outside of transaction' do
      it 'increments counter with in_transaction: "false"' do
        allow(ApplicationRecord.connection).to receive(:transaction_open?) { false }

        expect(described_class.internal_id_transactions_total).to receive(:increment)
          .with(operation: :track_greatest, usage: 'issues', in_transaction: 'false').and_call_original

        subject
      end
    end

    context 'when executed within transaction' do
      it 'increments counter with in_transaction: "true"' do
        expect(described_class.internal_id_transactions_total).to receive(:increment)
          .with(operation: :track_greatest, usage: 'issues', in_transaction: 'true').and_call_original

        InternalId.transaction { subject }
      end
    end
  end
end
