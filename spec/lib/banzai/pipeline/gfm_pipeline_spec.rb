# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::GfmPipeline do
  describe 'integration between parsing regular and external issue references' do
    let(:project) { create(:redmine_project, :public) }

    context 'when internal issue tracker is enabled' do
      context 'when shorthand pattern #ISSUE_ID is used' do
        it 'links an internal issues and keep updated nodes in result[:reference_filter_nodes]', :aggregate_failures do
          issue = create(:issue, project: project)
          markdown = "text #{issue.to_reference(project, full: true)}"

          result = described_class.call(markdown, project: project)
          link = result[:output].css('a').first
          text = result[:output].children.first

          expect(link['href']).to eq(Gitlab::Routing.url_helpers.project_issue_path(project, issue))
          expect(result[:reference_filter_nodes]).to eq([text])
        end
      end

      it 'executes :each_node only once for first reference filter', :aggregate_failures do
        issue = create(:issue, project: project)
        markdown = "text #{issue.to_reference(project, full: true)}"

        expect_any_instance_of(Banzai::Filter::References::ReferenceFilter).to receive(:each_node).once

        described_class.call(markdown, project: project)
      end

      context 'when shorthand pattern #ISSUE_ID is used' do
        it 'links an internal issue  if it exists' do
          issue = create(:issue, project: project)
          markdown = issue.to_reference(project, full: true)

          result = described_class.call(markdown, project: project)[:output]
          link = result.css('a').first

          expect(link['href']).to eq(
            Gitlab::Routing.url_helpers.project_issue_path(project, issue)
          )
        end

        it 'does not link any issue if it does not exist on GitLab' do
          markdown = '#12'

          result = described_class.call(markdown, project: project)[:output]
          expect(result.css('a')).to be_empty
        end
      end

      it 'allows to use long external reference syntax for Redmine' do
        markdown = 'API_32-12'

        result = described_class.call(markdown, project: project)[:output]
        link = result.css('a').first

        expect(link['href']).to eq 'http://issues.example.com/issues/12'
      end

      it 'parses cross-project references to regular issues' do
        other_project = create(:project, :public)
        issue = create(:issue, project: other_project)
        markdown = issue.to_reference(project, full: true)

        result = described_class.call(markdown, project: project)[:output]
        link = result.css('a').first

        expect(link['href']).to eq(
          Gitlab::Routing.url_helpers.project_issue_path(other_project, issue)
        )
      end
    end

    context 'when internal issue tracker is disabled' do
      before do
        project.issues_enabled = false
        project.save!
      end

      it 'allows to use shorthand external reference syntax for Redmine' do
        markdown = '#12'

        result = described_class.call(markdown, project: project)[:output]
        link = result.css('a').first

        expect(link['href']).to eq 'http://issues.example.com/issues/12'
      end

      it 'allows to use long external reference syntax for Redmine' do
        markdown = 'API_32-12'

        result = described_class.call(markdown, project: project)[:output]
        link = result.css('a').first

        expect(link['href']).to eq 'http://issues.example.com/issues/12'
      end

      it 'parses cross-project references to regular issues' do
        other_project = create(:project, :public)
        issue = create(:issue, project: other_project)
        markdown = issue.to_reference(project, full: true)

        result = described_class.call(markdown, project: project)[:output]
        link = result.css('a').first

        expect(link['href']).to eq(
          Gitlab::Routing.url_helpers.project_issue_path(other_project, issue)
        )
      end
    end
  end

  describe 'markdown link or image urls having spaces' do
    let(:project) { create(:project, :public) }

    it 'rewrites links with spaces in url' do
      markdown = "[Link to Page](page slug)"
      output = described_class.to_html(markdown, project: project)

      expect(output).to include("href=\"page%20slug\"")
    end

    it 'rewrites images with spaces in url' do
      markdown = "![My Image](test image.png)"
      output = described_class.to_html(markdown, project: project)

      expect(output).to include("src=\"test%20image.png\"")
    end

    it 'sanitizes the fixed link' do
      markdown_xss = "[xss](javascript: alert%28document.domain%29)"
      output = described_class.to_html(markdown_xss, project: project)

      expect(output).not_to include("javascript")

      markdown_xss = "<invalidtag>\n[xss](javascript:alert%28document.domain%29)"
      output = described_class.to_html(markdown_xss, project: project)

      expect(output).not_to include("javascript")
    end
  end

  describe 'emoji in references' do
    let_it_be(:project) { create(:project, :public) }

    let(:emoji) { '💯' }

    it 'renders a label reference with emoji inside' do
      create(:label, project: project, name: emoji)

      output = described_class.to_html("#{Label.reference_prefix}\"#{emoji}\"", project: project)

      expect(output).to include(emoji)
      expect(output).to include(Gitlab::Routing.url_helpers.project_issues_path(project, label_name: emoji))
    end

    it 'renders a milestone reference with emoji inside' do
      milestone = create(:milestone, project: project, title: emoji)

      output = described_class.to_html("#{Milestone.reference_prefix}\"#{emoji}\"", project: project)

      expect(output).to include(emoji)
      expect(output).to include(Gitlab::Routing.url_helpers.milestone_path(milestone))
    end
  end

  describe 'asset proxy' do
    let(:project) { create(:project, :public) }
    let(:image)   { '![proxy](http://example.com/test.png)' }
    let(:proxy)   { 'https://assets.example.com/08df250eeeef1a8cf2c761475ac74c5065105612/687474703a2f2f6578616d706c652e636f6d2f746573742e706e67' }
    let(:version) { Gitlab::CurrentSettings.current_application_settings.local_markdown_version }

    before do
      stub_asset_proxy_setting(enabled: true)
      stub_asset_proxy_setting(secret_key: 'shared-secret')
      stub_asset_proxy_setting(url: 'https://assets.example.com')
      stub_asset_proxy_setting(allowlist: %W(gitlab.com *.mydomain.com #{Gitlab.config.gitlab.host}))
      stub_asset_proxy_setting(domain_regexp: Banzai::Filter::AssetProxyFilter.compile_allowlist(Gitlab.config.asset_proxy.allowlist))
    end

    it 'replaces a lazy loaded img src' do
      output = described_class.to_html(image, project: project)
      doc    = Nokogiri::HTML.fragment(output)
      result = doc.css('img').first

      expect(result['data-src']).to eq(proxy)
    end

    it 'autolinks images to the proxy' do
      output = described_class.to_html(image, project: project)
      doc    = Nokogiri::HTML.fragment(output)
      result = doc.css('a').first

      expect(result['href']).to eq(proxy)
      expect(result['data-canonical-src']).to eq('http://example.com/test.png')
    end

    it 'properly adds tooltips to link for IDN images' do
      image  = '![proxy](http://exa😄mple.com/test.png)'
      proxy  = 'https://assets.example.com/6d8b634c412a23c6bfe1b2963f174febf5635ddd/687474703a2f2f6578612546302539462539382538346d706c652e636f6d2f746573742e706e67'
      output = described_class.to_html(image, project: project)
      doc    = Nokogiri::HTML.fragment(output)
      result = doc.css('a').first

      expect(result['href']).to eq(proxy)
      expect(result['data-canonical-src']).to eq('http://exa%F0%9F%98%84mple.com/test.png')
      expect(result['title']).to eq 'http://xn--example-6p25f.com/test.png'
    end
  end
end
