require 'spec_helper'

describe SlackMessage do
  subject { SlackMessage.new(args) }

  let(:args) {
    {
      after: 'after',
      before: 'before',
      project_name: 'project_name',
      ref: 'refs/heads/master',
      user_name: 'user_name',
      project_url: 'url'
    }
  }

  let(:color) { '#345' }

  context 'push' do
    before do
      args[:commits] = [
        { message: 'message1', url: 'url1', id: 'abcdefghijkl', author: { name: 'author1' } },
        { message: 'message2', url: 'url2', id: '123456789012', author: { name: 'author2' } },
      ]
    end

    it 'returns a message regarding pushes' do
      subject.pretext.should ==
        'user_name pushed to branch <url/commits/master|master> of '\
        '<url|project_name> (<url/compare/before...after|Compare changes>)'
      subject.attachments.should == [
        {
          text: "<url1|abcdefghi>: message1 - author1\n"\
                "<url2|123456789>: message2 - author2",
          color: color,
        }
      ]
    end
  end

  context 'new branch' do
    before do
      args[:before] = '000000'
    end

    it 'returns a message regarding a new branch' do
      subject.pretext.should ==
        'user_name pushed new branch <url/commits/master|master> to '\
        '<url|project_name>'
      subject.attachments.should be_empty
    end
  end

  context 'removed branch' do
    before do
      args[:after] = '000000'
    end

    it 'returns a message regarding a removed branch' do
      subject.pretext.should ==
        'user_name removed branch master from <url|project_name>'
      subject.attachments.should be_empty
    end
  end
end
