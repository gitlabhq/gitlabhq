require 'spec_helper'

describe SlackService::MergeMessage, models: true do
  subject { SlackService::MergeMessage.new(args) }

  let(:args) do
    {
      user: {
          name: 'Test User',
          username: 'Test User'
      },
      project_name: 'project_name',
      project_url: 'somewhere.com',

      object_attributes: {
        title: "Issue title\nSecond line",
        id: 10,
        iid: 100,
        assignee_id: 1,
        url: 'url',
        state: 'opened',
        description: 'issue description',
        source_branch: 'source_branch',
        target_branch: 'target_branch',
      }
    }
  end

  let(:color) { '#345' }

  context 'open' do
    it 'returns a message regarding opening of merge requests' do
      expect(subject.pretext).to eq(
        'Test User opened <somewhere.com/merge_requests/100|merge request #100> '\
        'in <somewhere.com|project_name>: *Issue title*')
      expect(subject.attachments).to be_empty
    end
  end

  context 'close' do
    before do
      args[:object_attributes][:state] = 'closed'
    end
    it 'returns a message regarding closing of merge requests' do
      expect(subject.pretext).to eq(
        'Test User closed <somewhere.com/merge_requests/100|merge request #100> '\
        'in <somewhere.com|project_name>: *Issue title*')
      expect(subject.attachments).to be_empty
    end
  end
end
