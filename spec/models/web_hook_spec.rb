# == Schema Information
#
# Table name: web_hooks
#
#  id                    :integer          not null, primary key
#  url                   :string(255)
#  project_id            :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  type                  :string(255)      default("ProjectHook")
#  service_id            :integer
#  push_events           :boolean          default(TRUE), not null
#  issues_events         :boolean          default(FALSE), not null
#  merge_requests_events :boolean          default(FALSE), not null
#

require 'spec_helper'

describe ProjectHook do
  describe "Associations" do
    it { should belong_to :project }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:project_id) }
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
      @project_hook = create(:project_hook)
      @project = create(:project)
      @project.hooks << [@project_hook]
      @data = { before: 'oldrev', after: 'newrev', ref: 'ref'}

      WebMock.stub_request(:post, @project_hook.url)
    end

    it "POSTs to the web hook URL" do
      @project_hook.execute(@data)
      WebMock.should have_requested(:post, @project_hook.url).once
    end

    it "POSTs the data as JSON" do
      json = @data.to_json

      @project_hook.execute(@data)
      WebMock.should have_requested(:post, @project_hook.url).with(body: json).once
    end

    it "catches exceptions" do
      WebHook.should_receive(:post).and_raise("Some HTTP Post error")

      lambda {
        @project_hook.execute(@data)
      }.should raise_error
    end
  end
end
