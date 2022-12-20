# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Web IDE routing", feature_category: :remote_development do
  describe 'remote' do
    it "routes to #index, without remote_path" do
      expect(post("/-/ide/remote/my.env.gitlab.example.com%3A3443")).to route_to(
        "web_ide/remote_ide#index",
        remote_host: 'my.env.gitlab.example.com:3443'
      )
    end

    it "routes to #index, with remote_path" do
      expect(post("/-/ide/remote/my.env.gitlab.example.com%3A3443/foo/bar.dev/test.dir")).to route_to(
        "web_ide/remote_ide#index",
        remote_host: 'my.env.gitlab.example.com:3443',
        remote_path: 'foo/bar.dev/test.dir'
      )
    end
  end
end
