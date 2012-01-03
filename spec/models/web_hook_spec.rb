require 'spec_helper'

describe WebHook do
  describe "Associations" do
    it { should belong_to :project }
  end

  describe "Validations" do
    it { should validate_presence_of(:url) }

    context "url format" do
      it { should allow_value("http://example.com").for(:url) }
      it { should allow_value("https://excample.com").for(:url) }
      it { should allow_value("http://test.com/api").for(:url) }
      it { should allow_value("http://test.com/api?key=abc").for(:url) }
      it { should allow_value("http://test.com/api?key=abc&type=def").for(:url) }

      it { should_not allow_value("example.com").for(:url) }
      it { should_not allow_value("ftp://example.com").for(:url) }
      it { should_not allow_value("herp-and-derp").for(:url) }
    end
  end

  describe "execute" do
    before(:each) do
      @webhook = Factory :web_hook
      @project = Factory :project
      @project.web_hooks << [@webhook]
      @data = { before: 'oldrev', after: 'newrev', ref: 'ref'}

      WebMock.stub_request(:post, @webhook.url)
    end

    it "POSTs to the web hook URL" do
      @webhook.execute(@data)
      WebMock.should have_requested(:post, @webhook.url).once
    end

    it "POSTs the data as JSON" do
      json = @data.to_json

      @webhook.execute(@data)
      WebMock.should have_requested(:post, @webhook.url).with(body: json).once
    end

    it "catches exceptions" do
      WebHook.should_receive(:post).and_raise("Some HTTP Post error")

      lambda {
        @webhook.execute(@data)
      }.should_not raise_error
    end
  end
end
# == Schema Information
#
# Table name: web_hooks
#
#  id         :integer         not null, primary key
#  url        :string(255)
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#

