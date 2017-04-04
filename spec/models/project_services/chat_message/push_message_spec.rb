require 'spec_helper'

describe ChatMessage::PushMessage, models: true do
  subject { described_class.new(args) }

  let(:args) do
    {
      after: 'after',
      before: 'before',
      project_name: 'project_name',
      ref: 'refs/heads/master',
      user_name: 'test.user',
      project_url: 'http://url.com'
    }
  end

  let(:color) { '#345' }

  context 'push' do
    before do
      args[:commits] = [
        { message: 'message1', url: 'http://url1.com', id: 'abcdefghijkl', author: { name: 'author1' } },
        { message: 'message2', url: 'http://url2.com', id: '123456789012', author: { name: 'author2' } },
      ]
    end

    it 'returns a message regarding pushes' do
      expect(subject.pretext).to eq(
        'test.user pushed to branch <http://url.com/commits/master|master> of '\
        '<http://url.com|project_name> (<http://url.com/compare/before...after|Compare changes>)'
      )
      expect(subject.attachments).to eq([
        {
          text: "<http://url1.com|abcdefgh>: message1 - author1\n"\
                "<http://url2.com|12345678>: message2 - author2",
          color: color,
        }
      ])
    end
  end

  context 'tag push' do
    let(:args) do
      {
        after: 'after',
        before: Gitlab::Git::BLANK_SHA,
        project_name: 'project_name',
        ref: 'refs/tags/new_tag',
        user_name: 'test.user',
        project_url: 'http://url.com'
      }
    end

    it 'returns a message regarding pushes' do
      expect(subject.pretext).to eq('test.user pushed new tag ' \
                                    '<http://url.com/commits/new_tag|new_tag> to ' \
                                    '<http://url.com|project_name>')
      expect(subject.attachments).to be_empty
    end
  end

  context 'new branch' do
    before do
      args[:before] = Gitlab::Git::BLANK_SHA
    end

    it 'returns a message regarding a new branch' do
      expect(subject.pretext).to eq(
        'test.user pushed new branch <http://url.com/commits/master|master> to '\
        '<http://url.com|project_name>'
      )
      expect(subject.attachments).to be_empty
    end
  end

  context 'removed branch' do
    before do
      args[:after] = Gitlab::Git::BLANK_SHA
    end

    it 'returns a message regarding a removed branch' do
      expect(subject.pretext).to eq(
        'test.user removed branch master from <http://url.com|project_name>'
      )
      expect(subject.attachments).to be_empty
    end
  end
end
