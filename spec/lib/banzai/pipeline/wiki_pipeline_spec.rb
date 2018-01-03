require 'rails_helper'

describe Banzai::Pipeline::WikiPipeline do
  describe 'TableOfContents' do
    it 'replaces the tag with the TableOfContentsFilter result' do
      markdown = <<-MD.strip_heredoc
          [[_TOC_]]

          ## Header

          Foo
      MD

      result = described_class.call(markdown, project: spy, project_wiki: spy)

      aggregate_failures do
        expect(result[:output].text).not_to include '[['
        expect(result[:output].text).not_to include 'TOC'
        expect(result[:output].to_html).to include(result[:toc])
      end
    end

    it 'is case-sensitive' do
      markdown = <<-MD.strip_heredoc
          [[_toc_]]

          # Header 1

          Foo
      MD

      output = described_class.to_html(markdown, project: spy, project_wiki: spy)

      expect(output).to include('[[<em>toc</em>]]')
    end

    it 'handles an empty pipeline result' do
      # No Markdown headers in this doc, so `result[:toc]` will be empty
      markdown = <<-MD.strip_heredoc
          [[_TOC_]]

          Foo
      MD

      output = described_class.to_html(markdown, project: spy, project_wiki: spy)

      aggregate_failures do
        expect(output).not_to include('<ul>')
        expect(output).not_to include('[[<em>TOC</em>]]')
      end
    end
  end

  describe "Links" do
    let(:namespace) { create(:namespace, name: "wiki_link_ns") }
    let(:project)   { create(:project, :public, name: "wiki_link_project", namespace: namespace) }
    let(:project_wiki) { ProjectWiki.new(project, double(:user)) }
    let(:page) { build(:wiki_page, wiki: project_wiki, page: OpenStruct.new(url_path: 'nested/twice/start-page')) }

    { "when GitLab is hosted at a root URL" => '/',
      "when GitLab is hosted at a relative URL" => '/nested/relative/gitlab' }.each do |test_name, relative_url_root|
      context test_name do
        before do
          allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return(relative_url_root)
        end

        describe "linking to pages within the wiki" do
          context "when creating hierarchical links to the current directory" do
            it "rewrites non-file links to be at the scope of the current directory" do
              markdown = "[Page](./page)"
              output = described_class.to_html(markdown, project: project, project_wiki: project_wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/wikis/nested/twice/page\"")
            end

            it "rewrites file links to be at the scope of the current directory" do
              markdown = "[Link to Page](./page.md)"
              output = described_class.to_html(markdown, project: project, project_wiki: project_wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/wikis/nested/twice/page.md\"")
            end
          end

          context "when creating hierarchical links to the parent directory" do
            it "rewrites non-file links to be at the scope of the parent directory" do
              markdown = "[Link to Page](../page)"
              output = described_class.to_html(markdown, project: project, project_wiki: project_wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/wikis/nested/page\"")
            end

            it "rewrites file links to be at the scope of the parent directory" do
              markdown = "[Link to Page](../page.md)"
              output = described_class.to_html(markdown, project: project, project_wiki: project_wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/wikis/nested/page.md\"")
            end
          end

          context "when creating hierarchical links to a sub-directory" do
            it "rewrites non-file links to be at the scope of the sub-directory" do
              markdown = "[Link to Page](./subdirectory/page)"
              output = described_class.to_html(markdown, project: project, project_wiki: project_wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/wikis/nested/twice/subdirectory/page\"")
            end

            it "rewrites file links to be at the scope of the sub-directory" do
              markdown = "[Link to Page](./subdirectory/page.md)"
              output = described_class.to_html(markdown, project: project, project_wiki: project_wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/wikis/nested/twice/subdirectory/page.md\"")
            end
          end

          describe "when creating non-hierarchical links" do
            it 'rewrites non-file links to be at the scope of the wiki root' do
              markdown = "[Link to Page](page)"
              output = described_class.to_html(markdown, project: project, project_wiki: project_wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/wikis/page\"")
            end

            it "rewrites file links to be at the scope of the current directory" do
              markdown = "[Link to Page](page.md)"
              output = described_class.to_html(markdown, project: project, project_wiki: project_wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/wikis/nested/twice/page.md\"")
            end

            it 'rewrites links with anchor' do
              markdown = '[Link to Header](start-page#title)'
              output = described_class.to_html(markdown, project: project, project_wiki: project_wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/wikis/start-page#title\"")
            end
          end

          describe "when creating root links" do
            it 'rewrites non-file links to be at the scope of the wiki root' do
              markdown = "[Link to Page](/page)"
              output = described_class.to_html(markdown, project: project, project_wiki: project_wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/wikis/page\"")
            end

            it 'rewrites file links to be at the scope of the wiki root' do
              markdown = "[Link to Page](/page.md)"
              output = described_class.to_html(markdown, project: project, project_wiki: project_wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/wikis/page.md\"")
            end
          end
        end

        describe "linking to pages outside the wiki (absolute)" do
          it "doesn't rewrite links" do
            markdown = "[Link to Page](http://example.com/page)"
            output = described_class.to_html(markdown, project: project, project_wiki: project_wiki, page_slug: page.slug)

            expect(output).to include('href="http://example.com/page"')
          end
        end
      end
    end
  end
end
