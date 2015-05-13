require 'spec_helper'

module Gitlab::Markdown
  describe RelativeLinkFilter do
    include ActionView::Helpers::TagHelper

    let!(:project) { create(:project) }

    let(:commit) { project.commit }
    let(:project_path) { project.path_with_namespace }
    let(:repository) { project.repository }
    let(:ref) { 'markdown' }

    let(:project_wiki) { nil }
    let(:requested_path) { '/' }
    let(:blob) { RepoHelpers.sample_blob }

    let(:context) do
      {
        commit: commit,
        project: project,
        project_wiki: project_wiki,
        requested_path: requested_path,
        ref: ref
      }
    end


    shared_examples :preserve_unchanged do

      it "should not modify any relative url in anchor" do
        doc = tag(:a, href: 'README.md')
        expect( filter(doc) ).to match '"README.md"'
      end

      it "should not modify any relative url in image" do
        doc = tag(:img, src: 'files/images/logo-black.png')
        expect( filter(doc) ).to match '"files/images/logo-black.png"'
      end
    end

    shared_examples :relative_to_requested do

      it "should rebuild url relative to the requested path" do
        expect( filter(tag(:a, href: 'users.md')) ).to \
          match %("/#{project_path}/blob/#{ref}/doc/api/users.md")
      end
    end


    context "with a project_wiki" do
      let(:project_wiki) { double('ProjectWiki') }

      include_examples :preserve_unchanged
    end

    context "without a repository" do
      let!(:project) { create(:empty_project) }

      include_examples :preserve_unchanged
    end

    context "with an empty repository" do
      let!(:project) { create(:project_empty_repo) }

      include_examples :preserve_unchanged
    end


    context "with a valid repository" do

      it "should rebuild relative url for a file in the repo" do
        expect( filter(tag(:a, href: 'doc/api/README.md')) ).to \
          match %("/#{project_path}/blob/#{ref}/doc/api/README.md")
      end

      it "should rebuild relative url for a file in the repo with an anchor" do
        expect( filter(tag(:a, href: 'README.md#section')) ).to \
          match %("/#{project_path}/blob/#{ref}/README.md#section")
      end

      it "should rebuild relative url for a directory in the repo" do
        expect( filter(tag(:a, href: 'doc/api/')) ).to \
          match %("/#{project_path}/tree/#{ref}/doc/api")
      end

      it "should rebuild relative url for an image in the repo" do
        expect( filter(tag(:img, src: 'files/images/logo-black.png')) ).to \
          match %("/#{project_path}/raw/#{ref}/files/images/logo-black.png")
      end

      it "should not modify relative url with an anchor only" do
        doc = tag(:a, href: '#section-1')
        expect( filter(doc) ).to match %("#section-1")
      end

      it "should not modify absolute url" do
        expect( filter(tag(:a, href: 'http://example.org')) ).to \
          match %("http://example.org")
      end

      context "when requested path is a file in the repo" do
        let(:requested_path) { 'doc/api/README.md' }

        include_examples :relative_to_requested
      end

      context "when requested path is a directory in the repo" do
        let(:requested_path) { 'doc/api' }

        include_examples :relative_to_requested
      end
    end


    def filter(doc)
      described_class.call(doc, context).to_s
    end
  end
end
