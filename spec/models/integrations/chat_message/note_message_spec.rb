# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ChatMessage::NoteMessage do
  subject { described_class.new(args) }

  let(:color) { '#345' }
  let(:args) do
    {
      user: {
        name: 'Test User',
        username: 'test.user',
        avatar_url: 'http://fakeavatar'
      },
      project_name: 'project_name',
      project_url: 'http://somewhere.com',
      repository: {
        name: 'project_name',
        url: 'http://somewhere.com'
      },
      object_attributes: {
        id: 10,
        note: 'comment on a commit',
        url: 'http://url.com',
        noteable_type: 'Commit'
      }
    }
  end

  context 'commit notes' do
    before do
      args[:object_attributes][:note] = 'comment on a commit'
      args[:object_attributes][:noteable_type] = 'Commit'
      args[:commit] = {
        id: '5f163b2b95e6f53cbd428f5f0b103702a52b9a23',
        message: "Added a commit message\ndetails\n123\n"
      }
    end

    context 'without markdown' do
      it 'returns a message regarding notes on commits' do
        expect(subject.pretext).to eq("Test User (test.user) <http://url.com|commented on " \
          "commit 5f163b2b> in <http://somewhere.com|project_name>: " \
          "*Added a commit message*")
        expect(subject.attachments).to eq([{
          text: 'comment on a commit',
          color: color
        }])
      end
    end

    context 'with markdown' do
      before do
        args[:markdown] = true
      end

      it 'returns a message regarding notes on commits' do
        expect(subject.pretext).to eq(
          'Test User (test.user) [commented on commit 5f163b2b](http://url.com) in [project_name](http://somewhere.com): *Added a commit message*'
        )
        expect(subject.attachments).to eq('comment on a commit')
        expect(subject.activity).to eq({
          title: 'Test User (test.user) [commented on commit 5f163b2b](http://url.com)',
          subtitle: 'in [project_name](http://somewhere.com)',
          text: 'Added a commit message',
          image: 'http://fakeavatar'
        })
      end
    end
  end

  context 'merge request notes' do
    before do
      args[:object_attributes][:note] = 'comment on a merge request'
      args[:object_attributes][:noteable_type] = 'MergeRequest'
      args[:merge_request] = {
        id: 1,
        iid: 30,
        title: "merge request title\ndetails\n"
      }
    end

    context 'without markdown' do
      it 'returns a message regarding notes on a merge request' do
        expect(subject.pretext).to eq("Test User (test.user) <http://url.com|commented on " \
          "merge request !30> in <http://somewhere.com|project_name>: " \
          "*merge request title*")
        expect(subject.attachments).to eq([{
          text: 'comment on a merge request',
          color: color
        }])
      end
    end

    context 'with markdown' do
      before do
        args[:markdown] = true
      end

      it 'returns a message regarding notes on a merge request' do
        expect(subject.pretext).to eq(
          'Test User (test.user) [commented on merge request !30](http://url.com) in [project_name](http://somewhere.com): *merge request title*')
        expect(subject.attachments).to eq('comment on a merge request')
        expect(subject.activity).to eq({
          title: 'Test User (test.user) [commented on merge request !30](http://url.com)',
          subtitle: 'in [project_name](http://somewhere.com)',
          text: 'merge request title',
          image: 'http://fakeavatar'
        })
      end
    end
  end

  context 'issue notes' do
    before do
      args[:object_attributes][:note] = 'comment on an issue'
      args[:object_attributes][:noteable_type] = 'Issue'
      args[:issue] = {
        id: 1,
        iid: 20,
        title: "issue title\ndetails\n"
      }
    end

    context 'without markdown' do
      it 'returns a message regarding notes on an issue' do
        expect(subject.pretext).to eq(
          "Test User (test.user) <http://url.com|commented on " \
            "issue #20> in <http://somewhere.com|project_name>: " \
            "*issue title*")
        expect(subject.attachments).to eq([{
          text: 'comment on an issue',
          color: color
        }])
      end
    end

    context 'with markdown' do
      before do
        args[:markdown] = true
      end

      it 'returns a message regarding notes on an issue' do
        expect(subject.pretext).to eq(
          'Test User (test.user) [commented on issue #20](http://url.com) in [project_name](http://somewhere.com): *issue title*')
        expect(subject.attachments).to eq('comment on an issue')
        expect(subject.activity).to eq({
          title: 'Test User (test.user) [commented on issue #20](http://url.com)',
          subtitle: 'in [project_name](http://somewhere.com)',
          text: 'issue title',
          image: 'http://fakeavatar'
        })
      end
    end
  end

  context 'project snippet notes' do
    before do
      args[:object_attributes][:note] = 'comment on a snippet'
      args[:object_attributes][:noteable_type] = 'Snippet'
      args[:snippet] = {
        id: 5,
        title: "snippet title\ndetails\n"
      }
    end

    context 'without markdown' do
      it 'returns a message regarding notes on a project snippet' do
        expect(subject.pretext).to eq("Test User (test.user) <http://url.com|commented on " \
          "snippet $5> in <http://somewhere.com|project_name>: " \
          "*snippet title*")
        expect(subject.attachments).to eq([{
          text: 'comment on a snippet',
          color: color
        }])
      end
    end

    context 'with markdown' do
      before do
        args[:markdown] = true
      end

      it 'returns a message regarding notes on a project snippet' do
        expect(subject.pretext).to eq(
          'Test User (test.user) [commented on snippet $5](http://url.com) in [project_name](http://somewhere.com): *snippet title*')
        expect(subject.attachments).to eq('comment on a snippet')
      end
    end
  end
end
