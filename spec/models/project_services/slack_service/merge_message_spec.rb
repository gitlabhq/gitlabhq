require 'spec_helper'

describe SlackService::MergeMessage do
  subject { SlackService::MergeMessage.new(args) }

  let(:args) {
    {
      user: {
        username: 'username'
      },
      project_name: 'project_name',
      project_url: 'somewhere.com',

      object_attributes: {
        title: 'Issue title',
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
  }

  let(:color) { '#345' }

  context 'open' do
    it 'returns a message regarding opening of merge requests' do
      expect(subject.pretext).to eq(
        'username opened merge request <somewhere.com/merge_requests/100|#100> '\
        'in <somewhere.com|project_name>')
      expect(subject.attachments).to be_empty
    end
  end

  context 'close' do
    before do
      args[:object_attributes][:state] = 'closed'
    end
    it 'returns a message regarding closing of merge requests' do
      expect(subject.pretext).to eq(
        'username closed merge request <somewhere.com/merge_requests/100|#100> '\
        'in <somewhere.com|project_name>')
      expect(subject.attachments).to be_empty
    end
  end
end
