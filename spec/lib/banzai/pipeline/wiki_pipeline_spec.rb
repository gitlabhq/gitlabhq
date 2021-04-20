# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::WikiPipeline do
  let_it_be(:namespace) { create(:namespace, name: "wiki_link_ns") }
  let_it_be(:project)   { create(:project, :public, name: "wiki_link_project", namespace: namespace) }
  let_it_be(:wiki)      { ProjectWiki.new(project, nil) }
  let_it_be(:page)      { build(:wiki_page, wiki: wiki, title: 'nested/twice/start-page') }

  describe 'TableOfContents' do
    it 'replaces the tag with the TableOfContentsFilter result' do
      markdown = <<-MD.strip_heredoc
          [[_TOC_]]

          ## Header

          Foo
      MD

      result = described_class.call(markdown, project: project, wiki: wiki)

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

      output = described_class.to_html(markdown, project: project, wiki: wiki)

      expect(output).to include('[[<em>toc</em>]]')
    end

    it 'handles an empty pipeline result' do
      # No Markdown headers in this doc, so `result[:toc]` will be empty
      markdown = <<-MD.strip_heredoc
          [[_TOC_]]

          Foo
      MD

      output = described_class.to_html(markdown, project: project, wiki: wiki)

      aggregate_failures do
        expect(output).not_to include('<ul>')
        expect(output).not_to include('[[<em>TOC</em>]]')
      end
    end
  end

  describe "Links" do
    { 'when GitLab is hosted at a root URL' => '',
      'when GitLab is hosted at a relative URL' => '/nested/relative/gitlab' }.each do |test_name, relative_url_root|
      context test_name do
        before do
          allow(Rails.application.routes).to receive(:default_url_options).and_return(script_name: relative_url_root)
        end

        describe "linking to pages within the wiki" do
          context "when creating hierarchical links to the current directory" do
            it "rewrites non-file links to be at the scope of the current directory" do
              markdown = "[Page](./page)"
              output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/-/wikis/nested/twice/page\"")
            end

            it "rewrites file links to be at the scope of the current directory" do
              markdown = "[Link to Page](./page.md)"
              output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/-/wikis/nested/twice/page.md\"")
            end
          end

          context "when creating hierarchical links to the parent directory" do
            it "rewrites non-file links to be at the scope of the parent directory" do
              markdown = "[Link to Page](../page)"
              output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/-/wikis/nested/page\"")
            end

            it "rewrites file links to be at the scope of the parent directory" do
              markdown = "[Link to Page](../page.md)"
              output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/-/wikis/nested/page.md\"")
            end
          end

          context "when creating hierarchical links to a sub-directory" do
            it "rewrites non-file links to be at the scope of the sub-directory" do
              markdown = "[Link to Page](./subdirectory/page)"
              output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/-/wikis/nested/twice/subdirectory/page\"")
            end

            it "rewrites file links to be at the scope of the sub-directory" do
              markdown = "[Link to Page](./subdirectory/page.md)"
              output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/-/wikis/nested/twice/subdirectory/page.md\"")
            end
          end

          describe "when creating non-hierarchical links" do
            it 'rewrites non-file links to be at the scope of the wiki root' do
              markdown = "[Link to Page](page)"
              output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/-/wikis/page\"")
            end

            it 'rewrites non-file links (with spaces) to be at the scope of the wiki root' do
              markdown = "[Link to Page](page slug)"
              output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/-/wikis/page%20slug\"")
            end

            it "rewrites file links to be at the scope of the current directory" do
              markdown = "[Link to Page](page.md)"
              output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/-/wikis/nested/twice/page.md\"")
            end

            it 'rewrites links with anchor' do
              markdown = '[Link to Header](start-page#title)'
              output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/-/wikis/start-page#title\"")
            end

            it 'rewrites links (with spaces) with anchor' do
              markdown = '[Link to Header](start page#title)'
              output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/-/wikis/start%20page#title\"")
            end
          end

          describe "when creating root links" do
            it 'rewrites non-file links to be at the scope of the wiki root' do
              markdown = "[Link to Page](/page)"
              output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/-/wikis/page\"")
            end

            it 'rewrites file links to be at the scope of the wiki root' do
              markdown = "[Link to Page](/page.md)"
              output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

              expect(output).to include("href=\"#{relative_url_root}/wiki_link_ns/wiki_link_project/-/wikis/page.md\"")
            end
          end
        end

        describe "linking to pages outside the wiki (absolute)" do
          it "doesn't rewrite links" do
            markdown = "[Link to Page](http://example.com/page)"
            output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

            expect(output).to include('href="http://example.com/page"')
          end
        end
      end
    end

    describe "checking slug validity when assembling links" do
      context "with a valid slug" do
        let(:valid_slug) { "http://example.com" }

        it "includes the slug in a (.) relative link" do
          output = described_class.to_html(
            "[Link](./alert(1);)",
            project: project,
            wiki: wiki,
            page_slug: valid_slug
          )

          expect(output).to include(valid_slug)
        end

        it "includeds the slug in a (..) relative link" do
          output = described_class.to_html(
            "[Link](../alert(1);)",
            project: project,
            wiki: wiki,
            page_slug: valid_slug
          )

          expect(output).to include(valid_slug)
        end
      end

      context "when the slug is deemed unsafe or invalid" do
        invalid_slugs = [
          "javascript:",
          "JaVaScRiPt:",
          "\u0001java\u0003script:",
          "javascript    :",
          "javascript:    ",
          "javascript    :   ",
          ":javascript:",
          "javascript&#58;",
          "javascript&#0058;",
          "javascript&#x3A;",
          "javascript&#x003A;",
          "java\0script:",
          " &#14;  javascript:"
        ]

        invalid_js_links = [
          "alert(1);",
          "alert(document.location);"
        ]

        invalid_slugs.each do |slug|
          context "with the invalid slug #{slug.delete("\000")}" do
            invalid_js_links.each do |link|
              it "doesn't include a prohibited slug in a (.) relative link '#{link}'" do
                output = described_class.to_html(
                  "[Link](./#{link})",
                  project: project,
                  wiki: wiki,
                  page_slug: slug
                )

                expect(output).not_to include(slug)
              end

              it "doesn't include a prohibited slug in a (..) relative link '#{link}'" do
                output = described_class.to_html(
                  "[Link](../#{link})",
                  project: project,
                  wiki: wiki,
                  page_slug: slug
                )

                expect(output).not_to include(slug)
              end
            end
          end
        end
      end
    end
  end

  describe 'videos and audio' do
    it 'generates video html structure' do
      markdown = "![video_file](video_file_name.mp4)"
      output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

      expect(output).to include('<video src="/wiki_link_ns/wiki_link_project/-/wikis/nested/twice/video_file_name.mp4"')
    end

    it 'rewrites and replaces video links names with white spaces to %20' do
      markdown = "![video file](video file name.mp4)"
      output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

      expect(output).to include('<video src="/wiki_link_ns/wiki_link_project/-/wikis/nested/twice/video%20file%20name.mp4"')
    end

    it 'generates audio html structure' do
      markdown = "![audio_file](audio_file_name.wav)"
      output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

      expect(output).to include('<audio src="/wiki_link_ns/wiki_link_project/-/wikis/nested/twice/audio_file_name.wav"')
    end

    it 'rewrites and replaces audio links names with white spaces to %20' do
      markdown = "![audio file](audio file name.wav)"
      output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)

      expect(output).to include('<audio src="/wiki_link_ns/wiki_link_project/-/wikis/nested/twice/audio%20file%20name.wav"')
    end
  end

  describe 'gollum tag filters' do
    context 'when local image file exists' do
      it 'sets the proper attributes for the image' do
        gollum_file_double = double('Gollum::File',
          mime_type: 'image/jpeg',
          name: 'images/image.jpg',
          path: 'images/image.jpg',
          data: '')

        wiki_file = Gitlab::Git::WikiFile.new(gollum_file_double)
        markdown = "[[#{wiki_file.path}]]"

        expect(wiki).to receive(:find_file).with(wiki_file.path, load_content: false).and_return(wiki_file)

        output = described_class.to_html(markdown, project: project, wiki: wiki, page_slug: page.slug)
        doc = Nokogiri::HTML::DocumentFragment.parse(output)

        full_path = "/wiki_link_ns/wiki_link_project/-/wikis/nested/twice/#{wiki_file.path}"
        expect(doc.css('a')[0].attr('href')).to eq(full_path)
        expect(doc.css('img')[0].attr('class')).to eq('gfm lazy')
        expect(doc.css('img')[0].attr('data-src')).to eq(full_path)
      end
    end
  end
end
