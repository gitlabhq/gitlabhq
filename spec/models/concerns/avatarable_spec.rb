require 'spec_helper'

describe Avatarable do
  subject { create(:project, avatar: fixture_file_upload(File.join(Rails.root, 'spec/fixtures/dk.png'))) }

  let(:gitlab_host) { "https://gitlab.example.com" }
  let(:relative_url_root) { "/gitlab" }
  let(:asset_host) { "https://gitlab-assets.example.com" }

  before do
    stub_config_setting(base_url: gitlab_host)
    stub_config_setting(relative_url_root: relative_url_root)
  end

  describe '#avatar_path' do
    using RSpec::Parameterized::TableSyntax

    where(:has_asset_host, :visibility_level, :only_path, :avatar_path) do
      true  | Project::PRIVATE  | true  | [gitlab_host, relative_url_root, subject.avatar.url]
      true  | Project::PRIVATE  | false | [gitlab_host, relative_url_root, subject.avatar.url]
      true  | Project::INTERNAL | true  | [gitlab_host, relative_url_root, subject.avatar.url]
      true  | Project::INTERNAL | false | [gitlab_host, relative_url_root, subject.avatar.url]
      true  | Project::PUBLIC   | true  | [subject.avatar.url]
      true  | Project::PUBLIC   | false | [asset_host, subject.avatar.url]
      false | Project::PRIVATE  | true  | [relative_url_root, subject.avatar.url]
      false | Project::PRIVATE  | false | [gitlab_host, relative_url_root, subject.avatar.url]
      false | Project::INTERNAL | true  | [relative_url_root, subject.avatar.url]
      false | Project::INTERNAL | false | [gitlab_host, relative_url_root, subject.avatar.url]
      false | Project::PUBLIC   | true  | [relative_url_root, subject.avatar.url]
      false | Project::PUBLIC   | false | [gitlab_host, relative_url_root, subject.avatar.url]
    end

    with_them do
      before do
        allow(ActionController::Base).to receive(:asset_host).and_return(has_asset_host ? asset_host : nil)
        subject.visibility_level = visibility_level
      end

      it 'returns the expected avatar path' do
        expect(subject.avatar_path(only_path: only_path)).to eq(avatar_path.join)
      end
    end
  end
end
