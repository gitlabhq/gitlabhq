require 'spec_helper'

describe Gitlab::Import::Github::Mapper::Milestone, lib: true do
  let(:project) { create(:empty_project) }
  let(:client)  { double(milestones: response) }

  let(:response) do
    [
      double(
        number: 2,
        state: 'open',
        title: 'v2.0',
        description: 'Tracking milestone for version 2.0',
        created_at: '2011-04-10T20:09:31Z',
        updated_at: '2014-03-03T18:58:10Z',
        closed_at: nil,
        due_on: '2012-10-09T23:39:01Z'
      ),
      double(
        number: 1,
        state: 'closed',
        title: 'v1.0',
        description: 'Tracking milestone for version 1.0',
        created_at: '2011-04-10T20:09:31Z',
        updated_at: '2014-03-03T18:58:10Z',
        closed_at: '2012-10-09T23:39:01Z',
        due_on: nil
      )
    ]
  end

  subject(:mapper) { described_class.new(project, client) }

  describe '#each' do
    it 'yields successively with Milestone' do
      expect { |block| mapper.each(&block) }.to yield_successive_args(Milestone, Milestone)
    end

    it 'matches the Milestone attributes' do
      milestone_opened = {
        project: project,
        iid: 2,
        title: 'v2.0',
        description: 'Tracking milestone for version 2.0',
        state: 'active',
        due_date: DateTime.strptime('2012-10-09T23:39:01Z'),
        created_at: DateTime.strptime('2011-04-10T20:09:31Z'),
        updated_at: DateTime.strptime('2014-03-03T18:58:10Z')
      }

      milestone_closed = {
        project: project,
        iid: 1,
        title: 'v1.0',
        description: 'Tracking milestone for version 1.0',
        state: 'closed',
        due_date: nil,
        created_at: DateTime.strptime('2011-04-10T20:09:31Z'),
        updated_at: DateTime.strptime('2012-10-09T23:39:01Z')
      }

      expected = [
        milestone_opened,
        milestone_closed
      ]

      mapper.each.with_index do |milestone, index|
        expect(milestone).to have_attributes(expected[index])
      end
    end
  end
end
