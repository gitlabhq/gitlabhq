# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MicrosoftTeams::Notifier do
  subject { described_class.new(webhook_url) }

  let(:webhook_url) { 'https://example.gitlab.com/' }
  let(:header) { { 'Content-Type' => 'application/json' } }
  let(:options) do
    {
      title: 'JohnDoe4/project2',
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
      "type" => "message",
      "attachments" => [
        {
          "contentType" => "application/vnd.microsoft.card.adaptive",
          "content" =>
          {
            "type" => "AdaptiveCard",
            msteams: { width: "Full" },
            "version" => "1.0",
            "body" => [
              {
                "type" => "TextBlock", "text" => "JohnDoe4/project2", "weight" => "bolder", "size" => "medium"
              },
              {
                "type" => "ColumnSet",
                "columns" => [
                  {
                    "type" => "Column", "width" => "auto", "items" => [{ "type" => "Image", "url" => "http://someimage.com", "size" => "medium" }]
                  },
                  {
                    "type" => "Column",
                    "width" => "stretch",
                    "items" => [
                      { "type" => "TextBlock", "text" => "Issue opened by user6", "weight" => "bolder", "wrap" => true },
                      { "type" => "TextBlock", "text" => "in [JohnDoe4/project2](http://localhost/namespace2/gitlabhq)", "isSubtle" => true, "wrap" => true },
                      { "type" => "TextBlock", "text" => "[#1 Awesome issue](http://localhost/namespace2/gitlabhq/issues/1)", "wrap" => true }
                    ]
                  }
                ]
              },
              { "type" => "TextBlock", "text" => "[GitLab](https://gitlab.com)\n\n- _Ruby_\n- **Go**\n", "wrap" => true }
            ]
          }
        }
      ]
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
