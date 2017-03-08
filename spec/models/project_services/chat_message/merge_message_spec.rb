require 'spec_helper'

describe ChatMessage::MergeMessage, models: true do
  subject { described_class.new(args) }

  let(:args) do
    {
      user: {
          name: 'Test User',
          username: 'test.user'
      },
      project_name: 'project_name',
      project_url: 'http://somewhere.com',

      object_attributes: {
        title: "Issue title\nSecond line",
        id: 10,
        iid: 100,
        assignee_id: 1,
        url: 'http://url.com',
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
        'test.user opened <http://somewhere.com/merge_requests/100|merge request !100> '\
        'in <http://somewhere.com|project_name>: *Issue title*')
      expect(subject.attachments).to be_empty
    end
  end

  context 'approval' do
    before do
      args[:object_attributes][:action] = 'approved'
    end

    it 'returns a message regarding approval of merge requests' do
      expect(subject.pretext).to eq(
        'test.user approved <http://somewhere.com/merge_requests/100|merge request !100> '\
        'in <http://somewhere.com|project_name>: *Issue title*')
      expect(subject.attachments).to be_empty
    end
  end

  context 'close' do
    before do
      args[:object_attributes][:state] = 'closed'
    end

    it 'returns a message regarding closing of merge requests' do
      expect(subject.pretext).to eq(
        'test.user closed <http://somewhere.com/merge_requests/100|merge request !100> '\
        'in <http://somewhere.com|project_name>: *Issue title*')
      expect(subject.attachments).to be_empty
    end
  end
end
