require_relative '../../app/models/project_services/slack_message'

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

  context 'push' do
    before do
      args[:commits] = [
        { message: 'message1', url: 'url1', id: 'abcdefghi' },
        { message: 'message2', url: 'url2', id: '123456789' },
      ]
    end

    it 'returns a message regarding pushes' do
      subject.compose.should ==
        'user_name pushed to branch <url/commits/master|master> of ' <<
        '<url|project_name> (<url/compare/before...after|Compare changes>)' <<
        "\n - message1 (<url1|abcdef>)" <<
        "\n - message2 (<url2|123456>)"
    end
  end

  context 'new branch' do
    before do
      args[:before] = '000000'
    end

    it 'returns a message regarding a new branch' do
      subject.compose.should ==
        'user_name pushed new branch <url/commits/master|master> to ' <<
        '<url|project_name>'
    end
  end

  context 'removed branch' do
    before do
      args[:after] = '000000'
    end

    it 'returns a message regarding a removed branch' do
      subject.compose.should ==
        'user_name removed branch master from <url|project_name>'
    end
  end
end
