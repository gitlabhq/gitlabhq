require 'spec_helper'

describe Avatarable do
  set(:project) { create(:project, avatar: fixture_file_upload(File.join(Rails.root, 'spec/fixtures/dk.png'))) }

  let(:gitlab_host) { "https://gitlab.example.com" }
  let(:relative_url_root) { "/gitlab" }
  let(:asset_host) { 'https://gitlab-assets.example.com' }

  before do
    stub_config_setting(base_url: gitlab_host)
    stub_config_setting(relative_url_root: relative_url_root)
  end

  describe '#avatar_path' do
    using RSpec::Parameterized::TableSyntax

    where(:has_asset_host, :visibility_level, :only_path, :avatar_path_prefix) do
      true  | Project::PRIVATE  | true  | [gitlab_host, relative_url_root]
      true  | Project::PRIVATE  | false | [gitlab_host, relative_url_root]
      true  | Project::INTERNAL | true  | [gitlab_host, relative_url_root]
      true  | Project::INTERNAL | false | [gitlab_host, relative_url_root]
      true  | Project::PUBLIC   | true  | []
      true  | Project::PUBLIC   | false | [asset_host]
      false | Project::PRIVATE  | true  | [relative_url_root]
      false | Project::PRIVATE  | false | [gitlab_host, relative_url_root]
      false | Project::INTERNAL | true  | [relative_url_root]
      false | Project::INTERNAL | false | [gitlab_host, relative_url_root]
      false | Project::PUBLIC   | true  | [relative_url_root]
      false | Project::PUBLIC   | false | [gitlab_host, relative_url_root]
    end

    with_them do
      before do
        allow(ActionController::Base).to receive(:asset_host) { has_asset_host && asset_host }

        project.visibility_level = visibility_level
      end

      let(:avatar_path) { (avatar_path_prefix + [project.avatar.url]).join }

      it 'returns the expected avatar path' do
        expect(project.avatar_path(only_path: only_path)).to eq(avatar_path)
      end
    end
  end
end
