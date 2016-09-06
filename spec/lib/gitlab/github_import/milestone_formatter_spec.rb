require 'spec_helper'

describe Gitlab::GithubImport::MilestoneFormatter, lib: true do
  let(:project) { create(:empty_project) }
  let(:created_at) { DateTime.strptime('2011-01-26T19:01:12Z') }
  let(:updated_at) { DateTime.strptime('2011-01-27T19:01:12Z') }
  let(:base_data) do
    {
      number: 1347,
      state: 'open',
      title: '1.0',
      description: 'Version 1.0',
      due_on: nil,
      created_at: created_at,
      updated_at: updated_at,
      closed_at: nil
    }
  end

  subject(:formatter) { described_class.new(project, raw_data)}

  describe '#attributes' do
    context 'when milestone is open' do
      let(:raw_data) { double(base_data.merge(state: 'open')) }

      it 'returns formatted attributes' do
        expected = {
          iid: 1347,
          project: project,
          title: '1.0',
          description: 'Version 1.0',
          state: 'active',
          due_date: nil,
          created_at: created_at,
          updated_at: updated_at
        }

        expect(formatter.attributes).to eq(expected)
      end
    end

    context 'when milestone is closed' do
      let(:raw_data) { double(base_data.merge(state: 'closed')) }

      it 'returns formatted attributes' do
        expected = {
          iid: 1347,
          project: project,
          title: '1.0',
          description: 'Version 1.0',
          state: 'closed',
          due_date: nil,
          created_at: created_at,
          updated_at: updated_at
        }

        expect(formatter.attributes).to eq(expected)
      end
    end

    context 'when milestone has a due date' do
      let(:due_date) { DateTime.strptime('2011-01-28T19:01:12Z') }
      let(:raw_data) { double(base_data.merge(due_on: due_date)) }

      it 'returns formatted attributes' do
        expected = {
          iid: 1347,
          project: project,
          title: '1.0',
          description: 'Version 1.0',
          state: 'active',
          due_date: due_date,
          created_at: created_at,
          updated_at: updated_at
        }

        expect(formatter.attributes).to eq(expected)
      end
    end
  end
end
