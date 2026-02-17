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

  def expect_replaces_placeholder(markdown, expected_text)
    result = run_pipeline(markdown, project: project, current_user: user, ref: current_ref, group: group)

    frag = Nokogiri::HTML.fragment("<p>")

    p = frag.children.first
    p['dir'] = 'auto'

    p << span = frag.document.create_element("span")
    span['data-placeholder'] = markdown
    span.content = expected_text

    expect(result).to eq_html(frag.to_html)
  end

  let_it_be(:gitlab_server) { Gitlab.config.gitlab.host }
  let_it_be(:gitlab_pages_domain) { Gitlab.config.pages.host }

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:project, reload: true) do
    create(:project, :small_repo, :public, group: group, create_tag: 'test', path: 'project-img')
  end

  let(:project_path) { project.full_path }
  let(:project_name) { project.path }
  let(:project_id) { project.id }
  let(:project_namespace) { project.project_namespace.to_param }

  let(:project_title) { project.title }
  let(:group_name) { project.group.name }
  let(:default_branch) { project.default_branch }
  let(:current_ref) { 'feature-branch' }
  let(:commit_sha) { project.commit.sha }
  let(:latest_tag) { project_tag }
  let(:empty_span) { '' }
  let(:project_tag) do
    if project.repository_exists?
      TagsFinder.new(project.repository, per_page: 1, sort: 'updated_desc')&.execute&.first&.name
    end
  end

  shared_examples 'placeholders with no access' do
    where(:markdown, :expected_text) do
      '%{gitlab_server}'       | ref(:gitlab_server)
      '%{gitlab_pages_domain}' | ref(:gitlab_pages_domain)
      '%{project_path}'        | ''
      '%{project_name}'        | ''
      '%{project_title}'       | ''
      '%{project_id}'          | ''
      '%{project_namespace}'   | ''
      '%{group_name}'          | ref(:group_name)
      '%{default_branch}'      | ''
      '%{current_ref}'         | ''
      '%{commit_sha}'          | ''
      '%{latest_tag}'          | ''
    end

    with_them do
      it 'replaces placeholder' do
        expect_replaces_placeholder(markdown, expected_text)
      end
    end
  end

  shared_examples 'placeholders with no access, no group' do
    where(:markdown, :expected_text) do
      '%{gitlab_server}'       | ref(:gitlab_server)
      '%{gitlab_pages_domain}' | ref(:gitlab_pages_domain)
      '%{project_path}'        | ''
      '%{project_name}'        | ''
      '%{project_title}'       | ''
      '%{project_id}'          | ''
      '%{project_namespace}'   | ''
      '%{group_name}'          | ''
      '%{default_branch}'      | ''
      '%{current_ref}'         | ''
      '%{commit_sha}'          | ''
      '%{latest_tag}'          | ''
    end

    with_them do
      it 'replaces placeholder' do
        expect_replaces_placeholder(markdown, expected_text)
      end
    end
  end

  shared_examples 'placeholders with access' do
    where(:markdown, :expected_text) do
      '%{gitlab_server}'       | ref(:gitlab_server)
      '%{gitlab_pages_domain}' | ref(:gitlab_pages_domain)
      '%{project_path}'        | ref(:project_path)
      '%{project_name}'        | ref(:project_name)
      '%{project_title}'       | ref(:project_title)
      '%{project_id}'          | ref(:project_id)
      '%{project_namespace}'   | ref(:project_namespace)
      '%{group_name}'          | ref(:group_name)
      '%{default_branch}'      | ref(:default_branch)
      '%{current_ref}'         | ref(:current_ref)
      '%{commit_sha}'          | ref(:commit_sha)
      '%{latest_tag}'          | ref(:latest_tag)
    end

    with_them do
      it 'replaces placeholder' do
        expect_replaces_placeholder(markdown, expected_text)
      end
    end
  end

  shared_examples 'placeholders with access, no code access' do
    where(:markdown, :expected_text) do
      '%{gitlab_server}'       | ref(:gitlab_server)
      '%{gitlab_pages_domain}' | ref(:gitlab_pages_domain)
      '%{project_path}'        | ref(:project_path)
      '%{project_name}'        | ref(:project_name)
      '%{project_title}'       | ref(:project_title)
      '%{project_id}'          | ref(:project_id)
      '%{project_namespace}'   | ref(:project_namespace)
      '%{group_name}'          | ref(:group_name)
      '%{default_branch}'      | ''
      '%{current_ref}'         | ''
      '%{commit_sha}'          | ''
      '%{latest_tag}'          | ''
    end

    with_them do
      it 'replaces placeholder' do
        expect_replaces_placeholder(markdown, expected_text)
      end
    end
  end

  context 'when `markdown_placeholders` feature flag is disabled' do
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
    let_it_be(:project, reload: true) { create(:project, :small_repo, group: private_group, create_tag: 'test') }

    context 'with no access' do
      it_behaves_like 'placeholders with no access, no group'
    end

    context 'with guest access' do
      before do
        private_group.add_member(user, Gitlab::Access::GUEST)
      end

      it_behaves_like 'placeholders with access, no code access'
    end

    context 'with reporter access' do
      before do
        private_group.add_member(user, Gitlab::Access::REPORTER)
      end

      it_behaves_like 'placeholders with access'
    end
  end

  context 'when project has a disabled repository' do
    let_it_be(:project, reload: true) { create(:project, :public, :repository_disabled, group: group) }

    it_behaves_like 'placeholders with access, no code access'
  end

  context 'when project has no repository' do
    let_it_be(:project, reload: true) { create(:project, :public, group: group) }

    it_behaves_like 'placeholders with access, no code access'
  end

  context 'when project is nil' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { nil }
    let_it_be(:group_name) { group.name }

    it_behaves_like 'placeholders with no access'
  end

  context 'when placeholders in link' do
    before do
      project.add_member(user, Gitlab::Access::OWNER)
    end

    it 'does not recognize unknown placeholder in a link href' do
      markdown = '[test](http://%{gitlab_server}/%{foo}/foo.png)'
      expected = %(<p dir="auto"><a href="http://localhost/%25%7Bfoo%7D/foo.png"
                   data-placeholder="http://%25%7Bgitlab_server%7D/%25%7Bfoo%7D/foo.png"
                   rel="nofollow noreferrer noopener" target="_blank"
                   data-canonical-src="http://%25%7Bgitlab_server%7D/%25%7Bfoo%7D/foo.png">test</a></p>)

      expect(run_pipeline(markdown)).to eq_html(expected)
    end

    it 'allows placeholders in link text' do
      markdown = '[%{gitlab_server}](http://%{gitlab_server})'
      expected = <<~HTML
        <p dir="auto">
          <a href="http://localhost" data-placeholder="http://%25%7Bgitlab_server%7D"
             data-canonical-src="http://%25%7Bgitlab_server%7D"
             rel="nofollow noreferrer noopener" target="_blank">
            <span data-placeholder="%{gitlab_server}">localhost</span>
          </a>
        </p>
      HTML

      expect(run_pipeline(markdown)).to eq_html(expected, trim_text_nodes: true)
    end

    it 'conserves percent-encoded input' do
      markdown = '[Careful!](https://example.com/foo%23%2fbar/%{gitlab_server}/)'
      expected_href = "https://example.com/foo%23%2fbar/#{Gitlab.config.gitlab.host}/"

      doc = Nokogiri::HTML.fragment(run_pipeline(markdown))
      expect(doc.css('a').first['href']).to eq(expected_href)
    end

    it "percent-encodes title but doesn't percent-encode path" do
      project.update!(title: 'Cool C++ Project')
      markdown = '[Visit %{project_title} at %{project_path}](https://example.com/%{project_path}/%{project_title})'
      # full_path should be included without encoding the '/'s, but title should be percent-encoded
      expected_href = "https://example.com/#{project.full_path}/Cool%20C%2B%2B%20Project"

      doc = Nokogiri::HTML.fragment(run_pipeline(markdown))
      expect(doc.css('a').first['href']).to eq(expected_href)
    end

    it "does not expand variables in the host portion which shouldn't be" do
      markdown = '[Not OK](https://%{project_title}.%{gitlab_server}/)'
      # The unreplaced %{project_title} placeholder should be exactly as it was in the
      # post-Markdown HTML, which is the same as it appears in data-placeholder.
      expected_data_placeholder = "https://%25%7Bproject_title%7D.%25%7Bgitlab_server%7D/"
      expected_href = "https://%25%7Bproject_title%7D.#{Gitlab.config.gitlab.host}/"

      doc = Nokogiri::HTML.fragment(run_pipeline(markdown))
      a = doc.css('a').first
      expect(a['data-placeholder']).to eq(expected_data_placeholder)
      expect(a['href']).to eq(expected_href)
    end

    it "does not expand variables in the path portion of a mailto: link which shouldn't be" do
      markdown = '[Not OK](mailto:hello@%{project_title}.%{gitlab_server})'
      expected_data_placeholder = "mailto:hello@%25%7Bproject_title%7D.%25%7Bgitlab_server%7D"
      expected_href = "mailto:hello@%25%7Bproject_title%7D.#{Gitlab.config.gitlab.host}"

      doc = Nokogiri::HTML.fragment(run_pipeline(markdown))
      a = doc.css('a').first
      expect(a['data-placeholder']).to eq(expected_data_placeholder)
      expect(a['href']).to eq(expected_href)
    end

    it 'works the same when the input originated from inline HTML' do
      # Combines several of the above checks, but all on an inline HTML link instead
      # of a Markdown one.  Note that the URL will get sanitised out by SanitizeLinkFilter
      # if it fails Addressable::URI.parse, and including "{" or "}" in the host part
      # will cause that, so we must percent-encode those.
      project.update!(title: 'Cool C++ Project')
      markdown = '<a href="https://%25%7Bproject_title%7D.%25%7Bgitlab_server%7D/foo%23%2fbar/' \
        '%{project_path}/%{project_title}" data-placeholder>Visit %{project_title} at %{project_path}</a>'
      expected_data_placeholder = "https://%25%7Bproject_title%7D.%25%7Bgitlab_server%7D/foo%23%2fbar/%{project_path}/%{project_title}"
      expected_href = "https://%25%7Bproject_title%7D.#{Gitlab.config.gitlab.host}/foo%23%2fbar/#{project.full_path}/Cool%20C%2B%2B%20Project"

      doc = Nokogiri::HTML.fragment(run_pipeline(markdown))
      a = doc.css('a').first
      expect(a['data-placeholder']).to eq(expected_data_placeholder)
      expect(a['href']).to eq(expected_href)
    end
  end

  context 'when placeholders in image' do
    before do
      project.add_member(user, Gitlab::Access::GUEST)
    end

    context 'when placeholder in the `src` attribute' do
      it 'generates the correct attributes' do
        markdown = '![](https://%{gitlab_server}/%{project_name}/foo.png)'
        expected = "<p><img src=\"https://#{Gitlab.config.gitlab.host}/#{project.path}/foo.png\" " \
          'data-placeholder="https://%25%7Bgitlab_server%7D/%25%7Bproject_name%7D/foo.png" alt="" ' \
          "data-src=\"https://#{Gitlab.config.gitlab.host}/#{project.path}/foo.png\" " \
          'data-canonical-src="https://%25%7Bgitlab_server%7D/%25%7Bproject_name%7D/foo.png"></p>'

        # can't use the pipeline because the image_link_filter modifies `src`
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
        expect(result).to include 'data-canonical-src="https://%25%7Bgitlab_server%7D/%25%7Bproject_name%7D/foo.png"'
        expect(result)
          .to include '<img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="'
      end
    end

    context 'when asset proxy is enabled' do
      before do
        stub_asset_proxy_enabled(
          url: 'https://assets.example.com',
          secret_key: 'shared-secret',
          allowlist: %w[gitlab.com *.mydomain.com]
        )
      end

      it 'generates the correct attributes' do
        markdown = '![](https://example.com/%{project_name}/foo.png)'

        result = run_pipeline(markdown)

        expect(result).to include 'href="https://assets.example.com/8641679ca136e7fe8cf9415852374bbe4595f929/68747470733a2f2f6578616d706c652e636f6d2f70726f6a6563742d696d672f666f6f2e706e67"'
        expect(result).to include 'f6f2e706e67" data-canonical-src="https://example.com/%25%7Bproject_name%7D/foo.png"'
        expect(result).to include 'data-src="https://assets.example.com/8641679ca136e7fe8cf9415852374bbe4595f929/68747470733a2f2f6578616d706c652e636f6d2f70726f6a6563742d696d672f666f6f2e706e67"'
        expect(result)
          .to include '<img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="'
      end
    end
  end

  context 'when placeholders in an unsupported node' do
    before do
      project.add_member(user, Gitlab::Access::GUEST)
    end

    it 'does not replace it' do
      markdown = '<code data-placeholder>%{gitlab-server}</code>'

      expect(run_filter(markdown)).to include '<code data-placeholder>%{gitlab-server}</code>'
    end
  end

  context 'when span[data-placeholder] contains more than just a placeholder' do
    let_it_be(:xss) do
      '<i/class=js-toggle-container><i/class=js-toggle-lazy-diff>' \
        '<i/class="file-holder"data-lines-path="/flightjs/xss/-/raw/main/a.json">' \
        '<i/class=gl-opacity-0><i/class="modal-backdrop"style="top&colon;-99px">' \
        '<i/class=diff-content><table><tbody/>'
    end

    let_it_be(:project) { create(:project, :small_repo, group: group, create_tag: xss) }
    let_it_be(:label) { create(:label, name: 'foo', description: 'xss %{latest_tag}', project: project) }

    before do
      project.add_member(user, Gitlab::Access::OWNER)
    end

    it "doesn't touch the content" do
      markdown = '<span data-placeholder>foo ~foo</span>'
      html = run_pipeline(markdown, project: project, current_user: user)

      # Not only should there be no XSS, %{latest_tag} shouldn't be substituted in at all and so it shouldn't
      # be present in its original or escaped form; we aren't doing substitutions in the title of an embedded
      # <a> just because someone added data-placeholder to a surrounding span.
      expect(html).not_to include("<i")
      expect(html).not_to include("&lt;i")
    end
  end

  describe described_class::PlaceholderReplacer do
    let(:all) { Banzai::Filter::PlaceholdersPostFilter::ALLOWED_URI_CONTEXT_ALL }
    let(:all_but_host) { Banzai::Filter::PlaceholdersPostFilter::ALLOWED_URI_CONTEXT_ALL_BUT_HOST }

    let(:replacement) { '# hello/world #' }
    let(:replacement_uri_encoded) { '%23%20hello%2Fworld%20%23' }

    it 'denies combination of ALLOWED_URI_CONTEXT_ALL with uri_encode: false' do
      expect do
        described_class.new(all, uri_encode: false)
      end.to raise_error(ArgumentError, /a security risk/)
    end

    it 'raises if an invalid allowed_uri_context is used' do
      expect do
        described_class.new(:xyz)
      end.to raise_error(ArgumentError)
    end

    context 'when permitted in all URI contexts' do
      subject(:replacer) { described_class.new(all) { replacement } }

      it 'replaces outside a URI' do
        expect(replacer.generate(nil, in_uri_component: false)).to eq(replacement)
      end

      it 'replaces inside a URI with encoding' do
        expect(replacer.generate(nil, in_uri_component: :path)).to eq(replacement_uri_encoded)
      end
    end

    context 'when permitted in all URI contexts except host' do
      subject(:replacer) { described_class.new(all_but_host) { replacement } }

      it 'replaces outside a URI' do
        expect(replacer.generate(nil, in_uri_component: false)).to eq(replacement)
      end

      it 'replaces inside a URI path with encoding' do
        expect(replacer.generate(nil, in_uri_component: :path)).to eq(replacement_uri_encoded)
      end

      it "doesn't replace inside a URI host" do
        expect(replacer.generate(nil, in_uri_component: :host)).to be_nil
      end
    end

    context 'when permitted in all URI contexts except host, with URI encoding disabled' do
      subject(:replacer) { described_class.new(all_but_host, uri_encode: false) { replacement } }

      it 'replaces outside a URI' do
        expect(replacer.generate(nil, in_uri_component: false)).to eq(replacement)
      end

      it 'replaces inside a URI path without encoding' do
        expect(replacer.generate(nil, in_uri_component: :path)).to eq(replacement)
      end

      it "doesn't replace inside a URI host" do
        expect(replacer.generate(nil, in_uri_component: :host)).to be_nil
      end
    end
  end

  it_behaves_like 'pipeline timing check'

  it_behaves_like 'a filter timeout' do
    let(:project_tag) { nil }
    let(:text) { 'text' }
  end

  it_behaves_like 'limits the number of filtered items' do
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
