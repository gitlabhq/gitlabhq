# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Rails/SaveBang -- None of the offenses are ActiveRecord calls
RSpec.shared_examples 'wiki_page' do |container_type|
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:container) { create(container_type) }
  let(:wiki) { container.wiki }

  def create_file_in_repository(path:)
    wiki.create_wiki_repository
    wiki.repository.create_file(
      user, path, 'test content',
      branch_name: wiki.default_branch,
      message: 'test commit'
    )

    title = Pathname(path).sub_ext('').to_s
    wiki.find_page(title)
  end

  def create_wiki_page(container, attrs = {})
    page = build_wiki_page(container, attrs)

    page.create(message: attrs[:message] || 'test commit')

    container.wiki.find_page(page.slug)
  end

  def build_wiki_page(container, attrs = {})
    wiki_page_attrs = { container: container, content: 'test content' }.merge(attrs)

    build(:wiki_page, wiki_page_attrs)
  end

  def force_wiki_change_branch
    old_default_branch = wiki.default_branch
    wiki.repository.add_branch(user, 'another_branch', old_default_branch)
    wiki.repository.rm_branch(user, old_default_branch)
    wiki.repository.expire_status_cache

    wiki.container.clear_memoization(:wiki)
  end

  before do
    container.add_owner(owner)
  end

  # Use for groups of tests that do not modify their `subject`.
  #
  #   include_context 'when subject is a persisted page', title: 'my title'
  shared_context 'when subject is a persisted page' do |attrs = {}|
    let(:persisted_page) { create_wiki_page(container, attrs) }

    subject { persisted_page }
  end

  describe '#meta' do
    let(:wiki_page) { create(:wiki_page, container: container, content: 'test content') }
    let!(:meta) { create(:wiki_page_meta, :for_wiki_page, container: container, wiki_page: wiki_page) }

    subject { wiki_page.meta }

    it 'finds the meta record for the page' do
      expect(subject).to eq(meta)
    end
  end

  describe '#front_matter' do
    let(:wiki_page) { create(:wiki_page, container: container, content: content) }

    shared_examples 'a page without front-matter' do
      it { expect(wiki_page).to have_attributes(front_matter: {}, content: content) }
    end

    shared_examples 'a page with front-matter' do
      let(:front_matter) { { title: 'Foo', slugs: %w[slug_a slug_b] } }

      it { expect(wiki_page.front_matter).to eq(front_matter) }
      it { expect(wiki_page.front_matter_title).to eq(front_matter[:title]) }
    end

    context 'when the wiki page has front matter' do
      let(:content) do
        <<~MD
        ---
        title: Foo
        slugs:
          - slug_a
          - slug_b
        ---

        My actual content
        MD
      end

      it_behaves_like 'a page with front-matter'

      it 'strips the front matter from the content' do
        expect(wiki_page.content.strip).to eq('My actual content')
      end
    end

    context 'when the wiki page does not have front matter' do
      let(:content) { 'My actual content' }

      it_behaves_like 'a page without front-matter'
    end

    context 'when the wiki page has fenced blocks, but nothing in them' do
      let(:content) do
        <<~MD
        ---
        ---

        My actual content
        MD
      end

      it_behaves_like 'a page without front-matter'
    end

    context 'when the wiki page has invalid YAML type in fenced blocks' do
      let(:content) do
        <<~MD
        ---
        this isn't YAML
        ---

        My actual content
        MD
      end

      it_behaves_like 'a page without front-matter'
    end

    context 'when the wiki page has a disallowed class in fenced block' do
      let(:content) do
        <<~MD
        ---
        date: 2010-02-11 11:02:57
        ---

        My actual content
        MD
      end

      it_behaves_like 'a page without front-matter'
    end

    context 'when the wiki page has invalid YAML in fenced block' do
      let(:content) do
        <<~MD
        ---
        invalid-use-of-reserved-indicator: @text
        ---

        My actual content
        MD
      end

      it_behaves_like 'a page without front-matter'
    end
  end

  describe '.unhyphenize' do
    it 'removes hyphens from a name' do
      name = 'a-name--with-hyphens'

      expect(described_class.unhyphenize(name)).to eq('a name with hyphens')
    end
  end

  describe "#initialize" do
    context "when initialized with an existing page" do
      include_context 'when subject is a persisted page', title: 'test initialization'

      it "sets the slug attribute" do
        expect(subject.slug).to eq("test-initialization")
      end

      it "sets the title attribute" do
        expect(subject.title).to eq("test initialization")
      end

      it "sets the formatted content attribute" do
        expect(subject.content).to eq("test content")
      end

      it "sets the format attribute" do
        expect(subject.format).to eq(:markdown)
      end

      it "sets the message attribute" do
        expect(subject.message).to eq("test commit")
      end

      it "sets the version attribute" do
        expect(subject.version).to be_a Gitlab::Git::WikiPageVersion
      end
    end
  end

  describe "validations" do
    subject { build_wiki_page(container) }

    it "validates presence of title" do
      subject.attributes.delete(:title)

      expect(subject).not_to be_valid
      expect(subject.errors.messages).to eq(title: ["can't be blank"])
    end

    it "does not validate presence of content" do
      subject.attributes.delete(:content)

      expect(subject).to be_valid
    end

    describe '#validate_content_size_limit' do
      context 'with a new page' do
        before do
          stub_application_setting(wiki_page_max_content_bytes: 10)
        end

        it 'accepts content below the limit' do
          subject.attributes[:content] = 'a' * 10

          expect(subject).to be_valid
        end

        it 'rejects content exceeding the limit' do
          subject.attributes[:content] = 'a' * 11

          expect(subject).not_to be_valid
          expect(subject.errors.messages).to eq(
            content: ['is too long (11 B). The maximum size is 10 B.']
          )
        end

        it 'counts content size in bytes rather than characters' do
          subject.attributes[:content] = '💩💩💩'

          expect(subject).not_to be_valid
          expect(subject.errors.messages).to eq(
            content: ['is too long (12 B). The maximum size is 10 B.']
          )
        end
      end

      context 'with an existing page exceeding the limit' do
        include_context 'when subject is a persisted page'

        before do
          subject
          stub_application_setting(wiki_page_max_content_bytes: 11)
        end

        it 'accepts content when it has not changed' do
          expect(subject).to be_valid
        end

        it 'rejects content when it has changed' do
          subject.attributes[:content] = 'a' * 12

          expect(subject).not_to be_valid
          expect(subject.errors.messages).to eq(
            content: ['is too long (12 B). The maximum size is 11 B.']
          )
        end
      end
    end

    describe '#validate_path_limits' do
      let(:max_title) { Gitlab::WikiPages::MAX_TITLE_BYTES }
      let(:max_directory) { Gitlab::WikiPages::MAX_DIRECTORY_BYTES }

      where(:character) do
        ['a', 'ä', '🙈']
      end

      with_them do
        let(:size) { character.bytesize.to_f }
        let(:valid_title) { character * (max_title / size).floor }
        let(:valid_directory) { character * (max_directory / size).floor }
        let(:invalid_title) { character * ((max_title + 1) / size).ceil }
        let(:invalid_directory) { character * ((max_directory + 1) / size).ceil }

        it 'accepts page titles below the limit' do
          subject.title = valid_title

          expect(subject).to be_valid
        end

        it 'accepts directories below the limit' do
          subject.title = "#{valid_directory}/foo"

          expect(subject).to be_valid
        end

        it 'accepts a path with page title and directory below the limit' do
          subject.title = "#{valid_directory}/#{valid_title}"

          expect(subject).to be_valid
        end

        it 'rejects page titles exceeding the limit' do
          subject.title = invalid_title

          expect(subject).not_to be_valid
          expect(subject.errors[:title]).to contain_exactly(
            "exceeds the limit of #{max_title} bytes"
          )
        end

        it 'rejects directories exceeding the limit' do
          subject.title = "#{invalid_directory}/#{invalid_directory}2/foo"

          expect(subject).not_to be_valid
          expect(subject.errors[:title]).to contain_exactly(
            "exceeds the limit of #{max_directory} bytes for directory name \"#{invalid_directory}\"",
            "exceeds the limit of #{max_directory} bytes for directory name \"#{invalid_directory}2\""
          )
        end

        it 'rejects a page with both title and directory exceeding the limit' do
          subject.title = "#{invalid_directory}/#{invalid_title}"

          expect(subject).not_to be_valid
          expect(subject.errors[:title]).to contain_exactly(
            "exceeds the limit of #{max_title} bytes",
            "exceeds the limit of #{max_directory} bytes for directory name \"#{invalid_directory}\""
          )
        end
      end

      context 'with an existing page title exceeding the limit' do
        subject do
          title = 'a' * (max_title + 1)
          wiki.create_page(title, 'content')
          wiki.find_page(title)
        end

        it 'accepts the exceeding title length when unchanged' do
          expect(subject).to be_valid
        end

        it 'rejects the exceeding title length when changed' do
          subject.title = 'b' * (max_title + 1)

          expect(subject).not_to be_valid
          expect(subject.errors).to include(:title)
        end
      end
    end
  end

  describe "#create" do
    let(:attributes) do
      {
        title: SecureRandom.hex,
        content: "Home Page",
        format: "markdown",
        message: 'Custom Commit Message'
      }
    end

    let(:title) { attributes[:title] }

    subject { build_wiki_page(container) }

    context "with valid attributes" do
      it "saves the wiki page" do
        subject.create(attributes)

        expect(wiki.find_page(title)).not_to be_nil
      end

      it "returns true" do
        expect(subject.create(attributes)).to be(true)
      end

      it 'saves the wiki page with message' do
        subject.create(attributes)

        expect(wiki.find_page(title).message).to eq 'Custom Commit Message'
      end

      it 'if the title is preceded by a / it is removed' do
        subject.create(attributes.merge(title: '/New Page'))

        expect(wiki.find_page('New Page')).not_to be_nil
      end
    end

    context "with invalid attributes" do
      it 'does not create the page' do
        expect { subject.create(title: '') }.not_to change { wiki.list_pages.length }
      end
    end

    context "with front matter context" do
      let(:attributes) do
        {
          title: SecureRandom.hex,
          content: "---\nxxx: abc\n---\nHome Page",
          format: "markdown",
          message: 'Custom Commit Message'
        }
      end

      it 'create the page with front matter' do
        subject.create(attributes)
        expect(wiki.find_page(title).front_matter).to eq({ xxx: "abc" })
      end
    end

    context "with existing page" do
      let(:title) { 'Existing Page' }

      it 'do not create the page with the same title' do
        page = create_wiki_page(container, title: title, content: 'content')

        subject.create(attributes.merge(title: title))
        expect(subject.create(attributes.merge(title: title))).to be_falsy
        expect(wiki.find_page(title).content).to eq(page.content)
      end

      it 'do not create the page with the same title, even if the orginal path contains spaces' do
        page = create_file_in_repository(path: "#{title}.md")

        subject.create(attributes.merge(title: title))
        expect(subject.create(attributes.merge(title: title))).to be_falsy
        expect(wiki.find_page(title).content).to eq(page.content)
      end
    end

    context 'when the repository fails' do
      it 'do not create the page if the repository raise an error' do
        page = build_wiki_page(container)

        allow(Gitlab::GitalyClient).to receive(:call) do
          raise GRPC::Unavailable, 'Gitaly broken in this spec'
        end

        saved = page.create(attributes)

        # unstub
        allow(Gitlab::GitalyClient).to receive(:call).and_call_original

        expect(saved).to be(false)
        expect(page.errors.messages[:base]).to include(/Gitaly broken in this spec/)
        expect(wiki.find_page(title)).to be_nil
      end
    end
  end

  describe "dot in the title" do
    let(:title) { 'Index v1.2.3' }

    describe "#create" do
      subject { build_wiki_page(container) }

      it "saves the wiki page and returns true", :aggregate_failures do
        attributes = { title: title, content: "Home Page", format: "markdown" }

        expect(subject.create(attributes)).to be(true)
        expect(wiki.find_page(title)).not_to be_nil
      end
    end

    describe '#update' do
      subject { create_wiki_page(container, title: title) }

      it 'updates the content of the page and returns true', :aggregate_failures do
        expect(subject.update(content: 'new content')).to be_truthy

        page = wiki.find_page(title)

        expect([subject.content, page.content]).to all(eq('new content'))
      end
    end
  end

  describe "#update" do
    let!(:original_title) { subject.title }

    subject { create_wiki_page(container) }

    context "with valid attributes" do
      it "updates the content of the page" do
        new_content = "new content"

        subject.update(content: new_content)
        page = wiki.find_page(original_title)

        expect([subject.content, page.content]).to all(eq("new content"))
      end

      it "updates the title of the page" do
        new_title = "Index v.1.2.4"

        subject.update(title: new_title)
        page = wiki.find_page(new_title)

        expect([subject.title, page.title]).to all(eq(new_title))
      end

      describe 'updating front_matter' do
        shared_examples 'able to update front-matter' do
          it 'updates the wiki-page front-matter' do
            content = subject.content
            subject.update(front_matter: { slugs: ['x'] })
            page = wiki.find_page(original_title)

            expect([subject, page]).to all(
              have_attributes(
                front_matter: include(slugs: include('x')),
                content: content
              ))
          end
        end

        it_behaves_like 'able to update front-matter'

        context 'when the front matter is too long' do
          let(:new_front_matter) do
            {
              title: generate(:wiki_page_title),
              slugs: Array.new(51).map { FFaker::Lorem.characters(512) }
            }
          end

          it 'raises an error' do
            expect do
              subject.update(front_matter: new_front_matter)
            end.to raise_error(described_class::FrontMatterTooLong)
          end
        end

        it 'updates the wiki-page front-matter and content together' do
          content = 'totally new content'
          subject.update(content: content, front_matter: { slugs: ['x'] })
          page = wiki.find_page(original_title)

          expect([subject, page]).to all(
            have_attributes(
              front_matter: include(slugs: include('x')),
              content: content
            ))
        end
      end

      it "returns true" do
        expect(subject.update(content: "more content")).to be_truthy
      end
    end

    context 'with same last commit sha' do
      it 'returns true' do
        expect(subject.update(content: 'more content', last_commit_sha: subject.last_commit_sha)).to be_truthy
      end
    end

    context 'with different last commit sha' do
      it 'raises exception' do
        expect do
          subject.update(content: 'more content', last_commit_sha: 'xxx')
        end.to raise_error(WikiPage::PageChangedError)
      end
    end

    describe 'in subdir' do
      it 'keeps the page in the same dir when the content is updated' do
        title = 'foo/Existing Page'
        page = create_wiki_page(container, title: title)

        expect(page.slug).to eq 'foo/Existing-Page'
        expect(page.update(title: title, content: 'new_content')).to be_truthy

        page = wiki.find_page(title)

        expect(page.slug).to eq 'foo/Existing-Page'
        expect(page.content).to eq 'new_content'
      end
    end

    context 'when renaming a page' do
      it 'raises an error if the page already exists' do
        existing_page = create_wiki_page(container)

        expect do
          subject.update(title: existing_page.title, content: 'new_content')
        end.to raise_error(WikiPage::PageRenameError)
        expect(subject.title).to eq original_title
        expect(subject.content).to eq 'new_content' # We don't revert the content
      end

      it 'updates the content and rename the file' do
        new_title = 'Renamed Page'
        new_content = 'updated content'

        expect(subject.update(title: new_title, content: new_content)).to be_truthy

        page = wiki.find_page(new_title)

        expect(page).not_to be_nil
        expect(page.content).to eq new_content
      end
    end

    context 'when moving a page' do
      it 'raises an error if the page already exists' do
        wiki.create_page('foo/Existing Page', 'content')

        expect do
          subject.update(title: 'foo/Existing Page', content: 'new_content')
        end.to raise_error(WikiPage::PageRenameError)
        expect(subject.title).to eq original_title
        expect(subject.content).to eq 'new_content'
      end

      it 'raises an error if the page already exists even if it contains spaces in the orginal path' do
        create_file_in_repository(path: 'foo/Existing Page.md')

        expect do
          subject.update(title: 'foo/Existing Page', content: 'new_content')
        end.to raise_error(WikiPage::PageRenameError)
        expect(subject.title).to eq original_title
        expect(subject.content).to eq 'new_content'
      end

      it 'updates the content and moves the file' do
        new_title = 'foo/Other Page'
        new_content = 'new_content'

        expect(subject.update(title: new_title, content: new_content)).to be_truthy

        page = wiki.find_page(new_title)

        expect(page).not_to be_nil
        expect(page.content).to eq new_content
      end

      context 'when page combine with directory' do
        it 'moving the file and directory' do
          wiki.create_page('testpage/testtitle', 'content')
          wiki.create_page('testpage', 'content')

          page = wiki.find_page('testpage')
          page.update(title: 'testfolder/testpage')

          page = wiki.find_page('testfolder/testpage/testtitle')

          expect(page.slug).to eq 'testfolder/testpage/testtitle'
        end
      end

      describe 'in subdir' do
        it 'moves the page to the root folder if the title is preceded by /' do
          page = create_wiki_page(container, title: 'foo/Existing Page')

          expect(page.slug).to eq 'foo/Existing-Page'
          expect(page.update(title: '/Existing Page', content: 'new_content')).to be_truthy
          expect(page.slug).to eq 'Existing-Page'
        end

        it 'does nothing if it has the same title' do
          page = create_wiki_page(container, title: 'foo/Another Existing Page')

          original_path = page.slug

          expect(page.update(title: 'Another Existing Page', content: 'new_content')).to be_truthy
          expect(page.slug).to eq original_path
        end

        it 'moves the page to the another folder if the original path has spaces' do
          page = create_file_in_repository(path: 'Existing Folder/Existing Page.md')

          original_path = page.slug

          expect(page.update(title: 'Existing Page', content: 'new_content')).to be_truthy
          expect(page.slug).not_to eq original_path
          expect(page.slug).to eq "Existing-Folder/Existing-Page"
        end
      end

      context 'in root dir' do
        it 'does nothing if the title is preceded by /' do
          original_path = subject.slug

          expect(subject.update(title: "/#{subject.title}", content: 'new_content')).to be_truthy
          expect(subject.slug).to eq original_path
        end
      end
    end

    context "with invalid attributes" do
      it 'aborts update if title blank' do
        expect(subject.update(title: '', content: 'new_content')).to be_falsey
        expect(subject.content).to eq 'new_content'

        page = wiki.find_page(original_title)

        expect(page.content).to eq 'test content'
      end
    end

    context 'when the repository fails' do
      it 'do not update the page if the repository raise an error' do
        page = create_wiki_page(container)

        allow(Gitlab::GitalyClient).to receive(:call) do
          raise GRPC::Unavailable, 'Gitaly broken in this spec'
        end

        saved = page.update(content: "new content")

        # unstub
        allow(Gitlab::GitalyClient).to receive(:call).and_call_original

        expect(saved).to be(false)
        expect(page.errors.messages[:base]).to include(/Gitaly broken in this spec/)

        page_found = wiki.find_page(original_title)

        expect(page_found.content).to eq 'test content'
      end
    end
  end

  describe "#delete" do
    it "deletes the page and returns true", :aggregate_failures do
      page = create_wiki_page(container)

      expect do
        expect(page.delete).to be(true)
      end.to change { wiki.list_pages.length }.by(-1)
    end

    context 'when the repository fails' do
      it 'do not delete the page if the repository raise an error' do
        page = create_wiki_page(container)

        allow(Gitlab::GitalyClient).to receive(:call) do
          raise GRPC::Unavailable, 'Gitaly broken in this spec'
        end

        deleted = page.delete

        # unstub
        allow(Gitlab::GitalyClient).to receive(:call).and_call_original

        expect(deleted).to be(false)
        expect(wiki.error_message).to match(/Gitaly broken in this spec/)
        expect(wiki.list_pages.length).to be(1)
      end
    end
  end

  describe "#versions" do
    subject { create_wiki_page(container) }

    before do
      3.times { |i| subject.update(content: "content #{i}") }
    end

    context 'when number of versions is less than the default paginiated per page' do
      it "returns an array of all commits for the page" do
        expect(subject.versions).to be_a(::CommitCollection)
        expect(subject.versions.length).to eq(4)
        expect(subject.versions.first.id).to eql(subject.last_version.id)
      end
    end

    context 'when number of versions is more than the default paginiated per page' do
      before do
        allow(Kaminari.config).to receive(:default_per_page).and_return(3)
      end

      it "returns an arrary containing the first page of commits for the page" do
        expect(subject.versions).to be_a(::CommitCollection)
        expect(subject.versions.length).to eq(3)
        expect(subject.versions.first.id).to eql(subject.last_version.id)
      end

      it "returns an arrary containing the second page of commits for the page with options[:page] = 2" do
        versions = subject.versions(page: 2)
        expect(versions).to be_a(::CommitCollection)
        expect(versions.length).to eq(1)
      end
    end

    context "when wiki repository's default is updated" do
      before do
        force_wiki_change_branch
      end

      it "returns the correct versions in the default branch" do
        page = container.wiki.find_page(subject.title)

        expect(page.versions).to be_a(::CommitCollection)
        expect(page.versions.length).to eq(4)
        expect(page.versions.first.id).to eql(page.last_version.id)

        page.update(content: "final content")
        expect(page.versions.length).to eq(5)
      end
    end
  end

  describe "#count_versions" do
    subject { create_wiki_page(container) }

    it "returns the total numbers of commits" do
      expect do
        3.times { |i| subject.update(content: "content #{i}") }
      end.to change { subject.count_versions }.from(1).to(4)
    end

    context "when wiki repository's default is updated" do
      before do
        subject
        force_wiki_change_branch
      end

      it "returns the correct number of versions in the default branch" do
        page = container.wiki.find_page(subject.title)
        expect(page.count_versions).to eq(1)

        page.update(content: "final content")
        expect(page.count_versions).to eq(2)
      end
    end
  end

  describe '#title_changed?' do
    using RSpec::Parameterized::TableSyntax

    let(:unsaved_page) { build_wiki_page(container, title: 'test page') }
    let(:existing_page) { create_wiki_page(container, title: 'test page') }
    let(:directory_page) { create_wiki_page(container, title: 'parent directory/child page') }
    let(:page_with_special_characters) { create_wiki_page(container, title: 'test+page') }

    let(:untitled_page) { described_class.new(wiki) }

    where(:page, :title, :changed) do
      :untitled_page  | nil                             | false
      :untitled_page  | 'new title'                     | true

      :unsaved_page   | nil                             | true
      :unsaved_page   | 'test page'                     | true
      :unsaved_page   | 'test-page'                     | true
      :unsaved_page   | 'test+page'                     | true
      :unsaved_page   | 'new title'                     | true

      :existing_page  | nil                             | false
      :existing_page  | 'test page'                     | false
      :existing_page  | 'test-page'                     | false
      :existing_page  | '/test page'                    | false
      :existing_page  | '/test-page'                    | false
      :existing_page  | 'test+page'                     | true
      :existing_page  | ' test page '                   | true
      :existing_page  | 'new title'                     | true
      :existing_page  | 'new-title'                     | true

      :directory_page | nil                             | false
      :directory_page | 'parent directory/child page'   | false
      :directory_page | 'parent-directory/child page'   | false
      :directory_page | 'parent-directory/child-page'   | false
      :directory_page | 'child page'                    | false
      :directory_page | 'child-page'                    | false
      :directory_page | '/child page'                   | true
      :directory_page | 'parent directory/other'        | true
      :directory_page | 'parent-directory/other'        | true
      :directory_page | 'parent-directory / child-page' | true
      :directory_page | 'other directory/child page'    | true
      :directory_page | 'other-directory/child page'    | true

      :page_with_special_characters | nil               | false
      :page_with_special_characters | 'test+page'       | false
      :page_with_special_characters | 'test-page'       | true
      :page_with_special_characters | 'test page'       | true
    end

    with_them do
      it 'returns the expected value' do
        subject = public_send(page)
        subject.title = title if title

        expect(subject.title_changed?).to be(changed)
      end
    end
  end

  describe '#content_changed?' do
    context 'with a new page' do
      subject { build_wiki_page(container) }

      it 'returns true if content is set' do
        subject.attributes[:content] = 'new'

        expect(subject.content_changed?).to be(true)
      end

      it 'returns false if content is blank' do
        subject.attributes[:content] = ' '

        expect(subject.content_changed?).to be(false)
      end
    end

    context 'with an existing page' do
      include_context 'when subject is a persisted page'

      it 'returns false' do
        expect(subject.content_changed?).to be(false)
      end

      it 'returns false if content is set to the same value' do
        subject.attributes[:content] = 'test content'

        expect(subject.content_changed?).to be(false)
      end

      it 'returns true if content is changed' do
        subject.attributes[:content] = 'new'

        expect(subject.content_changed?).to be(true)
      end

      it 'returns true if content is changed to a blank string' do
        subject.attributes[:content] = ' '

        expect(subject.content_changed?).to be(true)
      end

      it 'returns false if only the newline format has changed from LF to CRLF' do
        expect(subject.page).to receive(:text_data).and_return("foo\nbar")

        subject.attributes[:content] = "foo\r\nbar"

        expect(subject.content_changed?).to be(false)
      end

      it 'returns false if only the newline format has changed from CRLF to LF' do
        expect(subject.page).to receive(:text_data).and_return("foo\r\nbar")

        subject.attributes[:content] = "foo\nbar"

        expect(subject.content_changed?).to be(false)
      end
    end
  end

  describe '#path' do
    it 'returns the path when persisted' do
      existing_page = create_wiki_page(container, title: 'path test')

      expect(existing_page.path).to eq('path-test.md')
    end

    it 'returns nil when not persisted' do
      unsaved_page = build_wiki_page(container, title: 'path test')

      expect(unsaved_page.path).to be_nil
    end
  end

  describe '#directory' do
    context 'when the page is at the root directory' do
      include_context 'when subject is a persisted page', title: 'directory test'

      it 'returns an empty string' do
        expect(subject.directory).to eq('')
      end
    end

    context 'when the page is inside an actual directory' do
      include_context 'when subject is a persisted page', title: 'dir_1/dir_1_1/directory test'

      it 'returns the full directory hierarchy' do
        expect(subject.directory).to eq('dir_1/dir_1_1')
      end
    end
  end

  describe '#historical?' do
    let!(:container) { create(container_type) }
    let(:wiki) { subject.wiki }
    let(:old_version) { subject.versions.last.id }
    let(:old_page) { wiki.find_page(subject.title, old_version) }
    let(:latest_version) { subject.versions.first.id }
    let(:latest_page) { wiki.find_page(subject.title, latest_version) }

    subject { create_wiki_page(container) }

    before do
      3.times { |i| subject.update(content: "content #{i}") }
    end

    it 'returns true when requesting an old version' do
      expect(old_page.historical?).to be_truthy
    end

    it 'returns false when requesting latest version' do
      expect(latest_page.historical?).to be_falsy
    end

    it 'returns false when version is nil' do
      expect(latest_page).to receive(:version).and_return(nil)

      expect(latest_page.historical?).to be_falsy
    end

    it 'returns false when the last version is nil' do
      expect(old_page).to receive(:last_version).and_return(nil)

      expect(old_page.historical?).to be_falsy
    end

    it 'returns false when the version is nil' do
      expect(old_page).to receive(:version).and_return(nil)

      expect(old_page.historical?).to be_falsy
    end
  end

  describe '#persisted?' do
    it 'returns true for a persisted page' do
      expect(create_wiki_page(container)).to be_persisted
    end

    it 'returns false for an unpersisted page' do
      expect(build_wiki_page(container)).not_to be_persisted
    end
  end

  describe '#to_partial_path' do
    it 'returns the relative path to the partial to be used' do
      expect(build_wiki_page(container).to_partial_path).to eq('shared/wikis/wiki_page')
    end
  end

  describe '#==' do
    include_context 'when subject is a persisted page'

    it 'returns true for identical wiki page' do
      expect(subject == subject).to be(true)
    end

    it 'returns true for updated wiki page' do
      subject.update(content: "Updated content")
      updated_page = wiki.find_page(subject.slug)

      expect(updated_page).not_to be_nil
      expect(updated_page).to eq(subject)
    end

    it 'returns false for a completely different wiki page' do
      other_page = create(:wiki_page)

      expect(subject.slug).not_to eq(other_page.slug)
      expect(subject.container).not_to eq(other_page.container)
      expect(subject).not_to eq(other_page)
    end

    it 'returns false for page with different slug on same container' do
      other_page = create_wiki_page(container)

      expect(subject.slug).not_to eq(other_page.slug)
      expect(subject.container).to eq(other_page.container)
      expect(subject).not_to eq(other_page)
    end

    it 'returns false for page with the same slug on a different container' do
      other_page = create(:wiki_page, title: subject.slug)

      expect(subject.slug).to eq(other_page.slug)
      expect(subject.container).not_to eq(other_page.container)
      expect(subject).not_to eq(other_page)
    end
  end

  describe '#last_commit_sha' do
    include_context 'when subject is a persisted page'

    it 'returns commit sha' do
      expect(subject.last_commit_sha).to eq subject.last_version.sha
    end

    it 'is changed after page updated' do
      last_commit_sha_before_update = subject.last_commit_sha

      subject.update(content: "new content")
      page = wiki.find_page(subject.title)

      expect(page.last_commit_sha).not_to eq last_commit_sha_before_update
    end
  end

  describe '#hook_attrs' do
    subject { build_wiki_page(container) }

    it 'includes specific attributes' do
      keys = subject.hook_attrs.keys
      expect(keys).not_to include(:content)
      expect(keys).to include(:version_id)
    end
  end

  describe '#version_commit_timestamp' do
    context 'for a new page' do
      it 'returns nil' do
        expect(build_wiki_page(container).version_commit_timestamp).to be_nil
      end
    end

    context 'for page that exists' do
      it 'returns the timestamp of the commit' do
        existing_page = create_wiki_page(container)

        expect(existing_page.version_commit_timestamp).to eq(existing_page.version.commit.committed_date)
      end
    end
  end

  describe '#diffs' do
    include_context 'when subject is a persisted page'

    it 'returns a diff instance' do
      diffs = subject.diffs(foo: 'bar')

      expect(diffs).to be_a(Gitlab::Diff::FileCollection::WikiPage)
      expect(diffs.diffable).to be_a(Commit)
      expect(diffs.diffable.id).to eq(subject.version.id)
      expect(diffs.project).to be(subject.wiki)
      expect(diffs.diff_options).to include(
        expanded: true,
        paths: [subject.path],
        foo: 'bar'
      )
    end
  end

  describe "#human_title" do
    context "with front matter title" do
      let(:front_matter_title) { "abc" }
      let(:content_with_front_matter_title) { "---\ntitle: #{front_matter_title}\n---\nHome Page" }
      let(:wiki_page) { create(:wiki_page, container: container, content: content_with_front_matter_title) }

      it 'returns the front matter title' do
        expect(wiki_page.human_title).to eq front_matter_title
      end
    end
  end
end
# rubocop:enable Rails/SaveBang
