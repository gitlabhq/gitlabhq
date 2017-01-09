# == Schema Information
#
# Table name: web_hooks
#
#  id                :integer          not null, primary key
#  url               :string(255)
#  project_id        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  type              :string(255)      default("ProjectHook")
#  service_id        :integer
#  github_compatible :boolean          default(FALSE), not null
#

require 'spec_helper'
require 'cgi'

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
      it { should allow_value("http://user:password@test.com/api?key=abc&type=def").for(:url) }

      it { should_not allow_value("example.com").for(:url) }
      it { should_not allow_value("ftp://example.com").for(:url) }
      it { should_not allow_value("herp-and-derp").for(:url) }
    end
  end

  describe "github_compatible_data" do
    it "copies project.web_url to data.repository.url" do

      repo_url = "git@example.com:repository.git"
      repo_homepage = "http://example.com/repository"

      data = {
        before: 'oldrev',
        after: 'newrev',
        ref: 'ref',
        repository: {
          url: repo_url,
          homepage: repo_homepage
        }
      }

      result = WebHook.github_compatible_data(data)
      result[:repository].should include(:url => repo_homepage)
      result[:repository].should_not include(:homepage)
    end
  end

  describe "execute" do
    before(:each) do
      @project_hook = create(:project_hook)
      @project = create(:project)
      @project.hooks << [@project_hook]
      @project.path = "repository"

      @data = {
        before: 'oldrev',
        after: 'newrev',
        ref: 'ref',
        repository: {
          url: "git@example.com:repository.git"
        }
      }

      WebMock.stub_request(:post, @project_hook.url)
    end

    it "POSTs to the web hook URL" do
      @project_hook.execute(@data)
      WebMock.should have_requested(:post, @project_hook.url).once
    end

    it "catches exceptions" do
      WebHook.should_receive(:post).and_raise("Some HTTP Post error")

      lambda {
        @project_hook.execute(@data)
      }.should raise_error
    end

    context "with GitHub webhook format" do
      before do
        @project_hook.github_compatible = true
      end

      it "POSTs the data in GitHub compatible format" do
        @project_hook.execute(@data)
        transformed_data = WebHook.github_compatible_data(@data)
        WebMock.should have_requested(:post, @project_hook.url).
                           with(:body => "payload=" + CGI.escape(transformed_data.to_json)).
                           once
      end
    end

    context "with GitLab webhook format" do
      before do
        @project_hook.github_compatible = false
      end

      it "POSTs the data as JSON" do
        @project_hook.execute(@data)
        WebMock.should have_requested(:post, @project_hook.url).
                           with(:body => @data.to_json,
                                :headers => {'Content-Type' => 'application/json'}).
                           once
      end
    end

    context "with username and password in the URL" do
      it "adds the authorization header" do
        url_with_auth = "http://user:password@example.com/"

        auth_project_hook = create(:project_hook)
        auth_project_hook.url = url_with_auth

        WebMock.stub_request(:post, url_with_auth)

        auth_project_hook.execute("test")

        WebMock.should have_requested(:post, url_with_auth).once
      end
    end
  end
end
