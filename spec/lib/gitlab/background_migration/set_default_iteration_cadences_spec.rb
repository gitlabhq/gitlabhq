# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::SetDefaultIterationCadences, schema: 20201231133921 do
  let(:namespaces) { table(:namespaces) }
  let(:iterations) { table(:sprints) }
  let(:iterations_cadences) { table(:iterations_cadences) }

  describe '#perform' do
    context 'when no iteration cadences exists' do
      let!(:group_1) { namespaces.create!(name: 'group 1', path: 'group-1') }
      let!(:group_2) { namespaces.create!(name: 'group 2', path: 'group-2') }
      let!(:group_3) { namespaces.create!(name: 'group 3', path: 'group-3') }

      let!(:iteration_1) { iterations.create!(group_id: group_1.id, iid: 1, title: 'Iteration 1', start_date: 10.days.ago, due_date: 8.days.ago) }
      let!(:iteration_2) { iterations.create!(group_id: group_3.id, iid: 1, title: 'Iteration 2', start_date: 10.days.ago, due_date: 8.days.ago) }
      let!(:iteration_3) { iterations.create!(group_id: group_3.id, iid: 1, title: 'Iteration 3', start_date: 5.days.ago, due_date: 2.days.ago) }

      subject { described_class.new.perform(group_1.id, group_2.id, group_3.id, namespaces.last.id + 1) }

      before do
        subject
      end

      it 'creates iterations_cadence records for the requested groups' do
        expect(iterations_cadences.count).to eq(2)
      end

      it 'assigns the iteration cadences to the iterations correctly' do
        iterations_cadence = iterations_cadences.find_by(group_id: group_1.id)
        iteration_records = iterations.where(iterations_cadence_id: iterations_cadence.id)

        expect(iterations_cadence.start_date).to eq(iteration_1.start_date)
        expect(iterations_cadence.last_run_date).to eq(iteration_1.start_date)
        expect(iterations_cadence.title).to eq('group 1 Iterations')
        expect(iteration_records.size).to eq(1)
        expect(iteration_records.first.id).to eq(iteration_1.id)

        iterations_cadence = iterations_cadences.find_by(group_id: group_3.id)
        iteration_records = iterations.where(iterations_cadence_id: iterations_cadence.id)

        expect(iterations_cadence.start_date).to eq(iteration_3.start_date)
        expect(iterations_cadence.last_run_date).to eq(iteration_3.start_date)
        expect(iterations_cadence.title).to eq('group 3 Iterations')
        expect(iteration_records.size).to eq(2)
        expect(iteration_records.first.id).to eq(iteration_2.id)
        expect(iteration_records.second.id).to eq(iteration_3.id)
      end

      it 'does not call Group class' do
        expect(::Group).not_to receive(:where)

        subject
      end
    end

    context 'when an iteration cadence exists for a group' do
      let!(:group) { namespaces.create!(name: 'group', path: 'group') }

      let!(:iterations_cadence_1) { iterations_cadences.create!(group_id: group.id, start_date: 2.days.ago, title: 'Cadence 1') }

      let!(:iteration_1) { iterations.create!(group_id: group.id, iid: 1, title: 'Iteration 1', start_date: 10.days.ago, due_date: 8.days.ago) }
      let!(:iteration_2) { iterations.create!(group_id: group.id, iterations_cadence_id: iterations_cadence_1.id, iid: 2, title: 'Iteration 2', start_date: 5.days.ago, due_date: 3.days.ago) }

      subject { described_class.new.perform(group.id) }

      it 'does not create a new iterations_cadence' do
        expect { subject }.not_to change { iterations_cadences.count }
      end

      it 'assigns iteration cadences to iterations if needed' do
        subject

        expect(iteration_1.reload.iterations_cadence_id).to eq(iterations_cadence_1.id)
        expect(iteration_2.reload.iterations_cadence_id).to eq(iterations_cadence_1.id)
      end
    end
  end
end
