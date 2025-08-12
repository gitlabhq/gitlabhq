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

  def expect_replaces_placeholder(markdown, expected)
    result = run_pipeline(markdown, project: project, current_user: user)

    if expected
      expect(result).to eq "<p dir=\"auto\">#{expected}</p>"
    else
      expect(result).to eq "<p dir=\"auto\"><span data-placeholder=\"#{markdown}\"></span></p>"
    end
  end

  let_it_be(:gitlab_server) { "<span data-placeholder=\"%{gitlab_server}\">#{Gitlab.config.gitlab.host}</span>" }
  let_it_be(:gitlab_pages_domain) do
    "<span data-placeholder=\"%{gitlab_pages_domain}\">#{Gitlab.config.pages.host}</span>"
  end

  let!(:project_path) { "<span data-placeholder=\"%{project_path}\">#{project.full_path}</span>" }
  let!(:project_name) { "<span data-placeholder=\"%{project_name}\">#{project.path}</span>" }
  let!(:project_id) { "<span data-placeholder=\"%{project_id}\">#{project.id}</span>" }
  let!(:project_namespace) do
    "<span data-placeholder=\"%{project_namespace}\">#{project.project_namespace.to_param}</span>"
  end

  let!(:project_title) { "<span data-placeholder=\"%{project_title}\">#{project.title}</span>" }
  let!(:group_name) { "<span data-placeholder=\"%{group_name}\">#{project.group&.name}</span>" }
  let!(:default_branch) { "<span data-placeholder=\"%{default_branch}\">#{project.default_branch}</span>" }
  let!(:commit_sha) { "<span data-placeholder=\"%{commit_sha}\">#{project.commit&.sha}</span>" }
  let!(:latest_tag) { "<span data-placeholder=\"%{latest_tag}\">#{project_tag}</span>" }
  let!(:empty_span) { "<span data-placeholder=\"%{empty_span}\"></span>" }
  let!(:project_tag) do
    if project.repository_exists?
      TagsFinder.new(project.repository, per_page: 1, sort: 'updated_desc')&.execute&.first&.name
    end
  end

  shared_examples 'placeholders with no access' do
    where(:markdown, :expected) do
      '%{gitlab_server}'       | ref(:gitlab_server)
      '%{gitlab_pages_domain}' | ref(:gitlab_pages_domain)
      '%{project_path}'        | nil
      '%{project_name}'        | nil
      '%{project_title}'       | nil
      '%{project_id}'          | nil
      '%{project_namespace}'   | nil
      '%{group_name}'          | ref(:group_name)
      '%{default_branch}'      | nil
      '%{commit_sha}'          | nil
      '%{latest_tag}'          | nil
    end

    with_them do
      it 'replaces placeholder' do
        expect_replaces_placeholder(markdown, expected)
      end
    end
  end

  shared_examples 'placeholders with no access, no group' do
    where(:markdown, :expected) do
      '%{gitlab_server}'       | ref(:gitlab_server)
      '%{gitlab_pages_domain}' | ref(:gitlab_pages_domain)
      '%{project_path}'        | nil
      '%{project_name}'        | nil
      '%{project_title}'       | nil
      '%{project_id}'          | nil
      '%{project_namespace}'   | nil
      '%{group_name}'          | nil
      '%{default_branch}'      | nil
      '%{commit_sha}'          | nil
      '%{latest_tag}'          | nil
    end

    with_them do
      it 'replaces placeholder' do
        expect_replaces_placeholder(markdown, expected)
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
        expect_replaces_placeholder(markdown, expected)
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
      '%{default_branch}'      | nil
      '%{commit_sha}'          | nil
      '%{latest_tag}'          | nil
    end

    with_them do
      it 'replaces placeholder' do
        expect_replaces_placeholder(markdown, expected)
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
    let_it_be(:project, reload: true) { create(:project, :small_repo, :public, group: group) }

    it 'is sanitized' do
      allow(Gitlab.config.gitlab).to receive(:host).and_return('<script>')

      markdown = '%{gitlab_server}'

      expect(run_pipeline(markdown)).to include '<span data-placeholder="%{gitlab_server}"></span>'
    end
  end

  context 'when placeholders in link' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :small_repo, group: group) }

    before do
      project.add_member(user, Gitlab::Access::OWNER)
    end

    it 'does not allow project_title in a link href' do
      markdown = '[test](%{gitlab_server}/%{project_title}/foo.png)'
      expected = '<p dir="auto"><a href="localhost/%{project_title}/foo.png" ' \
        'data-placeholder="%%7Bgitlab_server%7D/%%7Bproject_title%7D/foo.png" ' \
        'rel="nofollow noreferrer noopener" target="_blank">test</a></p>'

      expect(run_pipeline(markdown)).to eq expected
    end

    it 'does not recognize unknown placeholder in a link href' do
      markdown = '[test](%{gitlab_server}/%{foo}/foo.png)'
      expected = '<p dir="auto"><a href="localhost/%%7Bfoo%7D/foo.png" ' \
        'data-placeholder="%%7Bgitlab_server%7D/%%7Bfoo%7D/foo.png" ' \
        'rel="nofollow noreferrer noopener" target="_blank">test</a></p>'

      expect(run_pipeline(markdown)).to eq expected
    end

    it 'does not allow placeholders in link text (parser limitation)' do
      markdown = '[%{gitlab_server}](%{gitlab_server})'
      expected = '<p dir="auto"><a href="localhost" data-placeholder="%%7Bgitlab_server%7D" ' \
        'rel="nofollow noreferrer noopener" target="_blank">%{gitlab_server}</a></p>'

      expect(run_pipeline(markdown)).to eq expected
    end

    context 'when replacing href' do
      it 'sanitizes the link' do
        allow(Gitlab.config.gitlab).to receive(:host).and_return('<script>')
        expect(Banzai::Filter::SanitizeLinkFilter).to receive(:new).twice.and_call_original

        markdown = '[foo](%{gitlab_server})'

        expect(run_pipeline(markdown))
          .to include "<a href=\"\""
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
          'data-placeholder="https://%%7Bgitlab_server%7D/%%7Bproject_name%7D/foo.png" alt="" ' \
          "data-src=\"https://#{Gitlab.config.gitlab.host}/#{project.path}/foo.png\" " \
          'data-canonical-src="https://%%7Bgitlab_server%7D/%%7Bproject_name%7D/foo.png"></p>'

        # can't use the pipeline because the image_link_filter modifies `src`
        expect(run_filter(markdown)).to eq expected
      end

      it 'does not allow project_title in a src' do
        markdown = '![](https://%{gitlab_server}/%{project_title}/foo.png)'
        expected = "<p><img src=\"https://#{Gitlab.config.gitlab.host}/%{project_title}/foo.png\" " \
          'data-placeholder="https://%%7Bgitlab_server%7D/%%7Bproject_title%7D/foo.png" alt="" ' \
          "data-src=\"https://#{Gitlab.config.gitlab.host}/%{project_title}/foo.png\" " \
          'data-canonical-src="https://%%7Bgitlab_server%7D/%%7Bproject_title%7D/foo.png"></p>'

        expect(run_filter(markdown)).to eq expected
      end

      it 'sanitizes the image' do
        allow(Gitlab.config.gitlab).to receive(:host).and_return('<script>')

        markdown = '![](https://%{gitlab_server}/%{project_name}/foo.png)'
        expected = "<p><img src=\"https:///#{project.path}/foo.png\" " \
          'data-placeholder="https://%%7Bgitlab_server%7D/%%7Bproject_name%7D/foo.png" alt="" ' \
          "data-src=\"https:///#{project.path}/foo.png\" " \
          'data-canonical-src="https://%%7Bgitlab_server%7D/%%7Bproject_name%7D/foo.png"></p>'

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

  context 'when tag has js- triggers' do
    let_it_be(:xss) do
      '<i/class=js-toggle-container><i/class=js-toggle-lazy-diff>' \
        '<i/class="file-holder"data-lines-path="/flightjs/xss/-/raw/main/a.json">' \
        '<i/class=gl-opacity-0><i/class="modal-backdrop"style="top&colon;-99px">' \
        '<i/class=diff-content><table><tbody/>'
    end

    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :small_repo, group: group, create_tag: xss) }
    let!(:label) { create(:label, name: 'foo', description: 'xss %{latest_tag}', project: project) }

    before do
      project.add_member(user, Gitlab::Access::OWNER)
    end

    it 'sanitizes and removes any js- triggers and tags' do
      expect(Banzai::Filter::SanitizationFilter).to receive(:new).twice.and_call_original

      markdown = '<span data-placeholder>foo ~foo</span>'
      html = run_pipeline(markdown, project: project, current_user: user)

      expect(html).not_to include 'js-'
      expect(html).to include 'title="xss "'
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
