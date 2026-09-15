# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Avatarable, feature_category: :shared do
  let(:project) { create(:project, :with_avatar) }

  let(:gitlab_host) { "https://gitlab.example.com" }
  let(:relative_url_root) { "/gitlab" }
  let(:asset_host) { 'https://gitlab-assets.example.com' }

  before do
    stub_config_setting(base_url: gitlab_host)
    stub_config_setting(relative_url_root: relative_url_root)
  end

  describe '#update' do
    let(:validator) { project.class.validators_on(:avatar).find { |v| v.is_a?(FileSizeValidator) } }

    context 'when avatar changed' do
      it 'validates the file size' do
        expect(validator).to receive(:validate_each).and_call_original

        project.update!(avatar: 'uploads/avatar.png')
      end
    end

    context 'when avatar was not changed' do
      it 'skips validation of file size' do
        expect(validator).not_to receive(:validate_each)

        project.update!(name: 'Hello world')
      end
    end
  end

  describe '#avatar_path' do
    let(:version_suffix) { "?v=#{project.updated_at.to_i}" }

    context 'with caching enabled', :request_store do
      let!(:avatar_path) { [relative_url_root, project.avatar.local_url].join + version_suffix }
      let!(:avatar_url) { [gitlab_host, relative_url_root, project.avatar.local_url].join + version_suffix }

      it 'only calls local_url once' do
        expect(project.avatar).to receive(:local_url).once.and_call_original

        2.times do
          expect(project.avatar_path).to eq(avatar_path)
        end
      end

      it 'calls local_url twice for path and URLs' do
        expect(project.avatar).to receive(:local_url).twice.and_call_original

        expect(project.avatar_path(only_path: true)).to eq(avatar_path)
        expect(project.avatar_path(only_path: false)).to eq(avatar_url)
      end

      it 'calls local_url twice for different sizes', :aggregate_failures do
        expect(project.avatar).to receive(:local_url).twice.and_call_original

        expect(project.avatar_path).to eq(avatar_path)

        path_with_size = project.avatar_path(size: 32)
        expect(path_with_size).to start_with(avatar_path.sub(version_suffix, ''))
        expect(path_with_size).to include("width=32")
        expect(path_with_size).to include("v=#{project.updated_at.to_i}")
      end

      it 'handles unpersisted objects' do
        new_project = build(:project, :with_avatar)
        path = [relative_url_root, new_project.avatar.local_url].join
        expect(new_project.avatar).to receive(:local_url).twice.and_call_original

        2.times do
          expect(new_project.avatar_path).to eq(path)
        end
      end
    end

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

      let(:avatar_path) { (avatar_path_prefix + [project.avatar.local_url]).join + version_suffix }

      it 'returns the expected avatar path' do
        expect(project.avatar_path(only_path: only_path)).to eq(avatar_path)
      end

      it 'returns the expected avatar path with width parameter', :aggregate_failures do
        result = project.avatar_path(only_path: only_path, size: 128)
        expect(result).to include("width=128")
        expect(result).to include("v=#{project.updated_at.to_i}")
      end

      context "when avatar is stored remotely" do
        before do
          stub_uploads_object_storage(AvatarUploader)

          project.avatar.migrate!(ObjectStorage::Store::REMOTE)
        end

        it 'returns the expected avatar path' do
          expect(project.avatar_url(only_path: only_path)).to eq(avatar_path)
        end
      end
    end

    it 'changes the URL when updated_at changes' do
      original_path = project.avatar_path
      project.update_column(:updated_at, 1.hour.from_now)
      project.reload

      expect(project.avatar_path).not_to eq(original_path)
    end
  end
end
