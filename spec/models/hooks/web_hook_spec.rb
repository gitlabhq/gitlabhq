# == Schema Information
#
# Table name: web_hooks
#
#  id                    :integer          not null, primary key
#  url                   :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  type                  :string(255)      default("ProjectHook")
#  service_id            :integer
#  push_events           :boolean          default(TRUE), not null
#  issues_events         :boolean          default(FALSE), not null
#  merge_requests_events :boolean          default(FALSE), not null
#  tag_push_events       :boolean          default(FALSE)
#  note_events           :boolean          default(FALSE), not null
#

require 'spec_helper'

describe WebHook, models: true do
  describe "Validations" do
    it { is_expected.to validate_presence_of(:url) }

    describe 'url' do
      it { is_expected.to allow_value("http://example.com").for(:url) }
      it { is_expected.to allow_value("https://example.com").for(:url) }
      it { is_expected.to allow_value(" https://example.com ").for(:url) }
      it { is_expected.to allow_value("http://test.com/api").for(:url) }
      it { is_expected.to allow_value("http://test.com/api?key=abc").for(:url) }
      it { is_expected.to allow_value("http://test.com/api?key=abc&type=def").for(:url) }

      it { is_expected.not_to allow_value("example.com").for(:url) }
      it { is_expected.not_to allow_value("ftp://example.com").for(:url) }
      it { is_expected.not_to allow_value("herp-and-derp").for(:url) }

      it 'strips :url before saving it' do
        hook = create(:project_hook, url: ' https://example.com ')

        expect(hook.url).to eq('https://example.com')
      end
    end
  end

  describe "execute" do
    before(:each) do
      @project_hook = create(:project_hook)
      @project = create(:project)
      @project.hooks << [@project_hook]
      @data = { before: 'oldrev', after: 'newrev', ref: 'ref' }

      WebMock.stub_request(:post, @project_hook.url)
    end

    it "POSTs to the webhook URL" do
      @project_hook.execute(@data, 'push_hooks')
      expect(WebMock).to have_requested(:post, @project_hook.url).with(
        headers: { 'Content-Type'=>'application/json', 'X-Gitlab-Event'=>'Push Hook' }
      ).once
    end

    it "POSTs the data as JSON" do
      @project_hook.execute(@data, 'push_hooks')
      expect(WebMock).to have_requested(:post, @project_hook.url).with(
        headers: { 'Content-Type'=>'application/json', 'X-Gitlab-Event'=>'Push Hook' }
      ).once
    end

    it "catches exceptions" do
      expect(WebHook).to receive(:post).and_raise("Some HTTP Post error")

      expect { @project_hook.execute(@data, 'push_hooks') }.to raise_error(RuntimeError)
    end

    it "handles SSL exceptions" do
      expect(WebHook).to receive(:post).and_raise(OpenSSL::SSL::SSLError.new('SSL error'))

      expect(@project_hook.execute(@data, 'push_hooks')).to eq([false, 'SSL error'])
    end

    it "handles 200 status code" do
      WebMock.stub_request(:post, @project_hook.url).to_return(status: 200, body: "Success")

      expect(@project_hook.execute(@data, 'push_hooks')).to eq([true, 'Success'])
    end

    it "handles 2xx status codes" do
      WebMock.stub_request(:post, @project_hook.url).to_return(status: 201, body: "Success")

      expect(@project_hook.execute(@data, 'push_hooks')).to eq([true, 'Success'])
    end
  end
end
