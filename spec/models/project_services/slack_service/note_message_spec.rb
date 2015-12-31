require 'spec_helper'

describe SlackService::NoteMessage, models: true do
  let(:color) { '#345' }

  before do
    @args = {
        user: {
            name: 'Test User',
            username: 'username',
            avatar_url: 'http://fakeavatar'
        },
        project_name: 'project_name',
        project_url: 'somewhere.com',
        repository: {
            name: 'project_name',
            url: 'somewhere.com',
        },
        object_attributes: {
            id: 10,
            note: 'comment on a commit',
            url: 'url',
            noteable_type: 'Commit'
        }
    }
  end

  context 'commit notes' do
    before do
      @args[:object_attributes][:note] = 'comment on a commit'
      @args[:object_attributes][:noteable_type] = 'Commit'
      @args[:commit] = {
          id: '5f163b2b95e6f53cbd428f5f0b103702a52b9a23',
          message: "Added a commit message\ndetails\n123\n"
      }
    end

    it 'returns a message regarding notes on commits' do
      message = SlackService::NoteMessage.new(@args)
      expect(message.pretext).to eq("Test User commented on " \
      "<url|commit 5f163b2b> in <somewhere.com|project_name>: " \
      "*Added a commit message*")
      expected_attachments = [
          {
              text: "comment on a commit",
              color: color,
          }
      ]
      expect(message.attachments).to eq(expected_attachments)
    end
  end

  context 'merge request notes' do
    before do
      @args[:object_attributes][:note] = 'comment on a merge request'
      @args[:object_attributes][:noteable_type] = 'MergeRequest'
      @args[:merge_request] = {
          id: 1,
          iid: 30,
          title: "merge request title\ndetails\n"
      }
    end
    it 'returns a message regarding notes on a merge request' do
      message = SlackService::NoteMessage.new(@args)
      expect(message.pretext).to eq("Test User commented on " \
      "<url|merge request #30> in <somewhere.com|project_name>: " \
      "*merge request title*")
      expected_attachments =  [
          {
              text: "comment on a merge request",
              color: color,
          }
      ]
      expect(message.attachments).to eq(expected_attachments)
    end
  end

  context 'issue notes' do
    before do
      @args[:object_attributes][:note] = 'comment on an issue'
      @args[:object_attributes][:noteable_type] = 'Issue'
      @args[:issue] = {
          id: 1,
          iid: 20,
          title: "issue title\ndetails\n"
      }
    end

    it 'returns a message regarding notes on an issue' do
      message = SlackService::NoteMessage.new(@args)
      expect(message.pretext).to eq(
        "Test User commented on " \
        "<url|issue #20> in <somewhere.com|project_name>: " \
        "*issue title*")
      expected_attachments = [
          {
              text: "comment on an issue",
              color: color,
          }
      ]
      expect(message.attachments).to eq(expected_attachments)
    end
  end

  context 'project snippet notes' do
    before do
      @args[:object_attributes][:note] = 'comment on a snippet'
      @args[:object_attributes][:noteable_type] = 'Snippet'
      @args[:snippet] = {
          id: 5,
          title: "snippet title\ndetails\n"
      }
    end

    it 'returns a message regarding notes on a project snippet' do
      message = SlackService::NoteMessage.new(@args)
      expect(message.pretext).to eq("Test User commented on " \
      "<url|snippet #5> in <somewhere.com|project_name>: " \
      "*snippet title*")
      expected_attachments =  [
          {
              text: "comment on a snippet",
              color: color,
          }
      ]
      expect(message.attachments).to eq(expected_attachments)
    end
  end
end
