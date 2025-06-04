# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::PlaceholdersPostFilter, feature_category: :markdown do
  include FilterSpecHelper
  using RSpec::Parameterized::TableSyntax

  def run_pipeline(text, context = { project: project })
    stub_commonmark_sourcepos_disabled

    Banzai.render_and_post_process(text, context)
  end

  def run_filter(text, context = { project: project })
    stub_commonmark_sourcepos_disabled

    text = Banzai::Filter::MarkdownFilter.new(text, context).call
    filter(text, context).to_html
  end

  let_it_be(:gitlab_server) { "<span data-placeholder>#{Gitlab.config.gitlab.host}</span>" }
  let_it_be(:gitlab_pages_domain) { "<span data-placeholder>#{Gitlab.config.pages.host}</span>" }
  let!(:project_path) { "<span data-placeholder>#{project.full_path}</span>" }
  let!(:project_name) { "<span data-placeholder>#{project.path}</span>" }
  let!(:project_id) { "<span data-placeholder>#{project.id}</span>" }
  let!(:project_namespace) { "<span data-placeholder>#{project.project_namespace.to_param}</span>" }
  let!(:project_title) { "<span data-placeholder>#{project.title}</span>" }
  let!(:group_name) { "<span data-placeholder>#{project.group&.name}</span>" }
  let!(:default_branch) { "<span data-placeholder>#{project.default_branch}</span>" }
  let!(:commit_sha) { "<span data-placeholder>#{project.commit&.sha}</span>" }
  let!(:latest_tag) { "<span data-placeholder>#{project_tag}</span>" }
  let!(:empty_span) { "<span data-placeholder></span>" }
  let!(:project_tag) do
    if project.repository_exists?
      TagsFinder.new(project.repository, per_page: 1, sort: 'updated_desc')&.execute&.first&.name
    end
  end

  shared_examples 'placeholders with no access' do
    where(:markdown, :expected) do
      '%{gitlab_server}'       | ref(:gitlab_server)
      '%{gitlab_pages_domain}' | ref(:gitlab_pages_domain)
      '%{project_path}'        | ref(:empty_span)
      '%{project_name}'        | ref(:empty_span)
      '%{project_title}'       | ref(:empty_span)
      '%{project_id}'          | ref(:empty_span)
      '%{project_namespace}'   | ref(:empty_span)
      '%{group_name}'          | ref(:group_name)
      '%{default_branch}'      | ref(:empty_span)
      '%{commit_sha}'          | ref(:empty_span)
      '%{latest_tag}'          | ref(:empty_span)
    end

    with_them do
      it 'replaces placeholder' do
        expect(run_pipeline(markdown, project: project, current_user: user)).to eq "<p dir=\"auto\">#{expected}</p>"
      end
    end
  end

  shared_examples 'placeholders with no access, no group' do
    where(:markdown, :expected) do
      '%{gitlab_server}'       | ref(:gitlab_server)
      '%{gitlab_pages_domain}' | ref(:gitlab_pages_domain)
      '%{project_path}'        | ref(:empty_span)
      '%{project_name}'        | ref(:empty_span)
      '%{project_title}'       | ref(:empty_span)
      '%{project_id}'          | ref(:empty_span)
      '%{project_namespace}'   | ref(:empty_span)
      '%{group_name}'          | ref(:empty_span)
      '%{default_branch}'      | ref(:empty_span)
      '%{commit_sha}'          | ref(:empty_span)
      '%{latest_tag}'          | ref(:empty_span)
    end

    with_them do
      it 'replaces placeholder' do
        expect(run_pipeline(markdown, project: project, current_user: user)).to eq "<p dir=\"auto\">#{expected}</p>"
      end
    end
  end

  shared_examples 'placeholders with access' do
    where(:markdown, :expected) do
      '%{gitlab_server}'       | ref(:gitlab_server)
      '%{gitlab_pages_domain}' | ref(:gitlab_pages_domain)
      '%{project_path}'        | ref(:project_path)
      '%{project_name}'        | ref(:project_name)
      '%{project_title}'       | ref(:project_title)
      '%{project_id}'          | ref(:project_id)
      '%{project_namespace}'   | ref(:project_namespace)
      '%{group_name}'          | ref(:group_name)
      '%{default_branch}'      | ref(:default_branch)
      '%{commit_sha}'          | ref(:commit_sha)
      '%{latest_tag}'          | ref(:latest_tag)
    end

    with_them do
      it 'replaces placeholder' do
        expect(run_pipeline(markdown, project: project, current_user: user)).to eq "<p dir=\"auto\">#{expected}</p>"
      end
    end
  end

  shared_examples 'placeholders with access, no code access' do
    where(:markdown, :expected) do
      '%{gitlab_server}'       | ref(:gitlab_server)
      '%{gitlab_pages_domain}' | ref(:gitlab_pages_domain)
      '%{project_path}'        | ref(:project_path)
      '%{project_name}'        | ref(:project_name)
      '%{project_title}'       | ref(:project_title)
      '%{project_id}'          | ref(:project_id)
      '%{project_namespace}'   | ref(:project_namespace)
      '%{group_name}'          | ref(:group_name)
      '%{default_branch}'      | ref(:empty_span)
      '%{commit_sha}'          | ref(:empty_span)
      '%{latest_tag}'          | ref(:empty_span)
    end

    with_them do
      it 'replaces placeholder' do
        expect(run_pipeline(markdown, project: project, current_user: user)).to eq "<p dir=\"auto\">#{expected}</p>"
      end
    end
  end

  context 'when `markdown_placeholders` feature flag is disabled' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :small_repo, :public, group: group) }

    before do
      stub_feature_flags(markdown_placeholders: false)
      project.add_member(user, Gitlab::Access::GUEST)
    end

    it 'does not replace placeholders' do
      expect(run_pipeline('%{gitlab_server}', project: project, current_user: user))
        .to eq '<p dir="auto">%{gitlab_server}</p>'
    end
  end

  context 'when disabled' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :small_repo, :public, group: group) }

    before do
      project.add_member(user, Gitlab::Access::GUEST)
    end

    it 'does not replace placeholders when :disable_placeholders' do
      result = run_pipeline('%{gitlab_server}', project: project, current_user: user, disable_placeholders: true)

      expect(result).to eq '<p dir="auto">%{gitlab_server}</p>'
    end

    it 'does not replace placeholders when :broadcast_message_placeholders' do
      result = run_pipeline('%{gitlab_server}', project: project, current_user: user,
        broadcast_message_placeholders: true)

      expect(result).to eq '<p dir="auto">%{gitlab_server}</p>'
    end
  end

  context 'when private project' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project, reload: true) { create(:project, :small_repo, group: group, create_tag: 'test') }

    context 'with no access' do
      it_behaves_like 'placeholders with no access'
    end

    context 'with guest access' do
      before do
        project.add_member(user, Gitlab::Access::GUEST)
      end

      it_behaves_like 'placeholders with access, no code access'
    end
  end

  context 'when public project' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project, reload: true) { create(:project, :small_repo, :public, group: group, create_tag: 'test') }

    context 'with no access' do
      it_behaves_like 'placeholders with access'
    end

    context 'with guest access' do
      before do
        project.add_member(user, Gitlab::Access::GUEST)
      end

      it_behaves_like 'placeholders with access'
    end
  end

  context 'when private group, private project' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group, reload: true) { create(:group, :private) }
    let_it_be(:project, reload: true) { create(:project, :small_repo, group: group, create_tag: 'test') }

    context 'with no access' do
      it_behaves_like 'placeholders with no access, no group'
    end

    context 'with guest access' do
      before do
        group.add_member(user, Gitlab::Access::GUEST)
      end

      it_behaves_like 'placeholders with access, no code access'
    end

    context 'with reporter access' do
      before do
        group.add_member(user, Gitlab::Access::REPORTER)
      end

      it_behaves_like 'placeholders with access'
    end
  end

  context 'when project has a disabled repository' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project, reload: true) { create(:project, :public, :repository_disabled, group: group) }

    it_behaves_like 'placeholders with access, no code access'
  end

  context 'when project has no repository' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project, reload: true) { create(:project, :public, group: group) }

    it_behaves_like 'placeholders with access, no code access'
  end

  context 'when placeholders in text' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :small_repo, group: group) }

    # if the validation is ever changed to allow characters such as `<`, then
    # we will need to sanitize the project_title
    it 'verifes project_title is limited in characters' do
      project.name = '<script>'

      expect { project.save! }.to raise_error(ActiveRecord::RecordInvalid)

      project.name = 'script:'

      expect { project.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'when placeholders in link' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :small_repo, group: group) }

    before do
      project.add_member(user, Gitlab::Access::GUEST)
    end

    it 'does not allow project_title in a link href' do
      markdown = '[test](%{gitlab_server}/%{project_title}/foo.png)'
      expected = '<p dir="auto"><a href="localhost/%{project_title}/foo.png" ' \
        'data-placeholder rel="nofollow noreferrer noopener" target="_blank">test</a></p>'

      expect(run_pipeline(markdown)).to eq expected
    end

    it 'does not recognize unknown placeholder in a link href' do
      markdown = '[test](%{gitlab_server}/%{foo}/foo.png)'
      expected = '<p dir="auto"><a href="localhost/%%7Bfoo%7D/foo.png" ' \
        'data-placeholder rel="nofollow noreferrer noopener" target="_blank">test</a></p>'

      expect(run_pipeline(markdown)).to eq expected
    end

    it 'does not allow placeholders in link text (parser limitation)' do
      markdown = '[%{gitlab_server}](%{gitlab_server})'
      expected = '<p dir="auto"><a href="localhost" data-placeholder rel="nofollow noreferrer noopener" ' \
        'target="_blank">%{gitlab_server}</a></p>'

      expect(run_pipeline(markdown)).to eq expected
    end

    context 'when replacing href' do
      let_it_be(:project) { create(:project, :small_repo, :public, group: group, path: 'script') }

      it 'sanitizes the link' do
        expect(Banzai::Filter::SanitizeLinkFilter).to receive(:new).twice.and_call_original

        markdown = '[foo](java%{project_name})'

        expect(run_pipeline(markdown)).to include "<a href=\"/#{project.full_path}/-/blob/master/javascript\""
      end
    end
  end

  context 'when placeholders in image' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :small_repo, :public, path: 'project-img', group: group) }

    before do
      project.add_member(user, Gitlab::Access::GUEST)
    end

    context 'when placeholder in the `src` attribute' do
      it 'generates the correct attributes' do
        markdown = '![](https://%{gitlab_server}/%{project_name}/foo.png)'
        expected = "<p><img src=\"https://#{Gitlab.config.gitlab.host}/#{project.path}/foo.png\" " \
          'data-placeholder alt="" ' \
          "data-src=\"https://#{Gitlab.config.gitlab.host}/#{project.path}/foo.png\" " \
          'data-canonical-src="https://%%7Bgitlab_server%7D/%%7Bproject_name%7D/foo.png"></p>'

        # can't use the pipeline because the image_link_filter modifies `src`
        expect(run_filter(markdown)).to eq expected
      end

      it 'does not allow project_title in a src' do
        markdown = '![](https://%{gitlab_server}/%{project_title}/foo.png)'
        expected = "<p><img src=\"https://#{Gitlab.config.gitlab.host}/%{project_title}/foo.png\" " \
          'data-placeholder alt="" ' \
          "data-src=\"https://#{Gitlab.config.gitlab.host}/%{project_title}/foo.png\" " \
          'data-canonical-src="https://%%7Bgitlab_server%7D/%%7Bproject_title%7D/foo.png"></p>'

        expect(run_filter(markdown)).to eq expected
      end
    end

    context 'when asset proxy is disabled' do
      before do
        stub_asset_proxy_setting(enabled: false)
      end

      it 'generates the correct attributes' do
        markdown = '![](https://%{gitlab_server}/%{project_name}/foo.png)'

        result = run_pipeline(markdown)

        expect(result).to include "href=\"https://#{Gitlab.config.gitlab.host}/#{project.path}/foo.png\""
        expect(result).to include "data-src=\"https://#{Gitlab.config.gitlab.host}/#{project.path}/foo.png\""
        expect(result).to include 'data-canonical-src="https://%%7Bgitlab_server%7D/%%7Bproject_name%7D/foo.png"'
        expect(result)
          .to include '<img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="'
      end
    end

    context 'when asset proxy is enabled' do
      before do
        stub_asset_proxy_setting(enabled: true)
        stub_asset_proxy_setting(secret_key: 'shared-secret')
        stub_asset_proxy_setting(url: 'https://assets.example.com')
        stub_asset_proxy_setting(allowlist: %w[gitlab.com *.mydomain.com])
      end

      it 'generates the correct attributes' do
        markdown = '![](https://example.com/%{project_name}/foo.png)'

        result = run_pipeline(markdown)

        expect(result).to include 'href="https://assets.example.com/8641679ca136e7fe8cf9415852374bbe4595f929/68747470733a2f2f6578616d706c652e636f6d2f70726f6a6563742d696d672f666f6f2e706e67"'
        expect(result).to include 'f6f2e706e67" data-canonical-src="https://example.com/%%7Bproject_name%7D/foo.png"'
        expect(result).to include 'data-src="https://assets.example.com/8641679ca136e7fe8cf9415852374bbe4595f929/68747470733a2f2f6578616d706c652e636f6d2f70726f6a6563742d696d672f666f6f2e706e67"'
        expect(result)
          .to include '<img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="'
      end
    end
  end

  context 'when placeholders in an unsupported node' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :small_repo, :public, path: 'project-img', group: group) }

    before do
      project.add_member(user, Gitlab::Access::GUEST)
    end

    it 'does not replace it' do
      markdown = '<code data-placeholder>%{gitlab-server}</code>'

      expect(run_filter(markdown)).to include '<code data-placeholder>%{gitlab-server}</code>'
    end
  end

  it_behaves_like 'pipeline timing check' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project) }
  end

  it_behaves_like 'a filter timeout' do
    let_it_be(:project_tag) { nil }
    let(:text) { 'text' }
  end

  it_behaves_like 'limits the number of filtered items' do
    let_it_be(:project) { create(:project) }
    let(:text) do
      '<span data-placeholder>%{gitlab_server}</span> <span data-placeholder>%{gitlab_server}</span> ' \
        '<span data-placeholder>%{gitlab_server}</span>'
    end

    let(:ends_with) { '<span data-placeholder>%{gitlab_server}</span>' }

    before do
      stub_const('Banzai::Filter::PlaceholdersPostFilter::FILTER_ITEM_LIMIT', 2)
    end
  end
end
