# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MicrosoftTeams::Notifier do
  subject { described_class.new(webhook_url) }

  let(:webhook_url) { 'https://example.gitlab.com/' }
  let(:header) { { 'Content-Type' => 'application/json' } }
  let(:options) do
    {
      title: 'JohnDoe4/project2',
      summary: '[[JohnDoe4/project2](http://localhost/namespace2/gitlabhq)] Issue [#1 Awesome issue](http://localhost/namespace2/gitlabhq/issues/1) opened by user6',
      activity: {
        title: 'Issue opened by user6',
        subtitle: 'in [JohnDoe4/project2](http://localhost/namespace2/gitlabhq)',
        text: '[#1 Awesome issue](http://localhost/namespace2/gitlabhq/issues/1)',
        image: 'http://someimage.com'
      },
      attachments: "[GitLab](https://gitlab.com)\n\n- _Ruby_\n- **Go**\n"
    }
  end

  let(:body) do
    {
      'sections' => [
        {
          'activityTitle' => 'Issue opened by user6',
          'activitySubtitle' => 'in [JohnDoe4/project2](http://localhost/namespace2/gitlabhq)',
          'activityText' => '[#1 Awesome issue](http://localhost/namespace2/gitlabhq/issues/1)',
          'activityImage' => 'http://someimage.com'
        },
        {
          text: "[GitLab](https://gitlab.com)\n\n- _Ruby_\n- **Go**\n"
        }
      ],
      'title' => 'JohnDoe4/project2',
      'summary' => '[[JohnDoe4/project2](http://localhost/namespace2/gitlabhq)] Issue [#1 Awesome issue](http://localhost/namespace2/gitlabhq/issues/1) opened by user6'
    }
  end

  describe '#ping' do
    before do
      stub_request(:post, webhook_url).with(body: JSON(body), headers: { 'Content-Type' => 'application/json' }).to_return(status: 200, body: "", headers: {})
    end

    it 'expects to receive successful answer' do
      expect(subject.ping(options)).to be true
    end
  end

  describe '#body' do
    it 'returns Markdown-based body when HTML was passed' do
      expect(subject.send(:body, **options)).to eq(body.to_json)
    end

    it 'fails when empty Hash was passed' do
      expect { subject.send(:body, **{}) }.to raise_error(ArgumentError)
    end
  end
end
