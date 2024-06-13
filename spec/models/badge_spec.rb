# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Badge do
  let(:placeholder_url) { 'http://www.example.com/%{project_path}/%{project_id}/%{project_name}/%{project_namespace}/%{group_name}/%{gitlab_server}/%{gitlab_pages_domain}/%{default_branch}/%{commit_sha}/%{project_title}/%{latest_tag}' }

  describe 'validations' do
    # Requires the let variable url_sym
    shared_examples 'placeholder url' do
      let(:badge) { build(:badge) }

      it 'allows url with http protocol' do
        badge[url_sym] = 'http://www.example.com'

        expect(badge).to be_valid
      end

      it 'allows url with https protocol' do
        badge[url_sym] = 'https://www.example.com'

        expect(badge).to be_valid
      end

      it 'cannot be empty' do
        badge[url_sym] = ''

        expect(badge).not_to be_valid
      end

      it 'cannot be nil' do
        badge[url_sym] = nil

        expect(badge).not_to be_valid
      end

      it 'accept badges placeholders' do
        badge[url_sym] = placeholder_url

        expect(badge).to be_valid
      end

      it 'sanitize url' do
        badge[url_sym] = 'javascript:alert(1)'

        expect(badge).not_to be_valid
      end
    end

    context 'link_url format' do
      let(:url_sym) { :link_url }

      it_behaves_like 'placeholder url'
    end

    context 'image_url format' do
      let(:url_sym) { :image_url }

      it_behaves_like 'placeholder url'
    end
  end

  shared_examples 'rendered_links' do
    context 'when the repository is not nil' do
      let_it_be(:full_path) { project.full_path }
      let_it_be(:id) { project.id }
      let_it_be(:path) { project.path }
      let_it_be(:title) { project.title }
      let_it_be(:default_branch) { 'master' }
      let_it_be(:tag) { 'v1.1.1' }
      let_it_be(:commit_sha) { project.commit&.sha }
      let_it_be(:project_namespace) { project.project_namespace.to_param }
      let_it_be(:group_name) { project.group&.to_param }
      let_it_be(:gitlab_server) { ::Gitlab.config.gitlab.host }
      let_it_be(:gitlab_pages_domain) { "example.com" }

      it 'uses the project information to populate the url placeholders' do
        url = "http://www.example.com/#{full_path}/#{id}/#{path}/#{project_namespace}/#{group_name}/#{gitlab_server}" \
          "/#{gitlab_pages_domain}/#{default_branch}/#{commit_sha}/#{title}/#{tag}"

        expect(badge.public_send("rendered_#{method}", project)).to eq(url)
      end

      it 'returns the url if the project used is nil' do
        expect(badge.public_send("rendered_#{method}", nil)).to eq placeholder_url
      end
    end

    context 'when the repository is nil' do
      let_it_be(:full_path_empty_repo) { project_empty_repo.full_path }
      let_it_be(:id_empty_repo) { project_empty_repo.id }
      let_it_be(:path_empty_repo) { project_empty_repo.path }
      let_it_be(:title_empty_repo) { project_empty_repo.title }
      let_it_be(:project_namespace_empty_repo) { project_empty_repo.project_namespace.to_param }
      # Using constant values for the placeholders which won't be populated in the placeholder_url as there is no repo
      # and group
      let_it_be(:default_branch_empty_repo) { '%{default_branch}' }
      let_it_be(:tag_empty_repo) { '%{latest_tag}' }
      let_it_be(:commit_sha_empty_repo) { '%{commit_sha}' }
      let_it_be(:group_name_empty_repo) { '%{group_name}' }
      let_it_be(:gitlab_server_empty_repo) { ::Gitlab.config.gitlab.host }
      let_it_be(:gitlab_pages_domain_empty_repo) { "example.com" }

      it 'populate the placeholders' do
        url = "http://www.example.com/#{full_path_empty_repo}/#{id_empty_repo}/#{path_empty_repo}/" \
          "#{project_namespace_empty_repo}/#{group_name_empty_repo}/#{gitlab_server_empty_repo}/" \
          "#{gitlab_pages_domain_empty_repo}/#{default_branch_empty_repo}/#{commit_sha_empty_repo}/" \
          "#{title_empty_repo}/#{tag_empty_repo}"

        expect(badge.public_send("rendered_#{method}", project_empty_repo)).to eq(url)
      end
    end
  end

  context 'methods' do
    let(:badge) { build(:badge, link_url: placeholder_url, image_url: placeholder_url) }
    let_it_be(:project) { create(:project, :repository, :in_group) }
    let_it_be(:project_empty_repo) { create(:project, :empty_repo) }

    describe '#rendered_link_url' do
      let(:method) { :link_url }

      it_behaves_like 'rendered_links'
    end

    describe '#rendered_image_url' do
      let(:method) { :image_url }

      it_behaves_like 'rendered_links'

      context 'when asset proxy is enabled' do
        let(:placeholder_url) { 'http://www.example.com/image' }

        before do
          stub_asset_proxy_setting(
            enabled: true,
            url: 'https://assets.example.com',
            secret_key: 'shared-secret'
          )
        end

        it 'returns a proxied URL' do
          expect(badge.rendered_image_url).to start_with('https://assets.example.com')
        end
      end
    end
  end
end
