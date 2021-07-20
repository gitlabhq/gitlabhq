# frozen_string_literal: true

require "spec_helper"

RSpec.describe WikiPage do
  let_it_be(:user) { create(:user) }
  let_it_be(:container) { create(:project) }

  def create_wiki_page(attrs = {})
    page = build_wiki_page(attrs)

    page.create(message: (attrs[:message] || 'test commit'))

    container.wiki.find_page(page.slug)
  end

  def build_wiki_page(attrs = {})
    wiki_page_attrs = { container: container, content: 'test content' }.merge(attrs)

    build(:wiki_page, wiki_page_attrs)
  end

  def wiki
    container.wiki
  end

  def disable_front_matter
    stub_feature_flags(Gitlab::WikiPages::FrontMatterParser::FEATURE_FLAG => false)
  end

  def enable_front_matter_for(thing)
    stub_feature_flags(Gitlab::WikiPages::FrontMatterParser::FEATURE_FLAG => thing)
  end

  # Use for groups of tests that do not modify their `subject`.
  #
  #   include_context 'subject is persisted page', title: 'my title'
  shared_context 'subject is persisted page' do |attrs = {}|
    let_it_be(:persisted_page) { create_wiki_page(attrs) }

    subject { persisted_page }
  end

  describe '#front_matter' do
    let(:wiki_page) { create(:wiki_page, container: container, content: content) }

    shared_examples 'a page without front-matter' do
      it { expect(wiki_page).to have_attributes(front_matter: {}, content: content) }
    end

    shared_examples 'a page with front-matter' do
      let(:front_matter) { { title: 'Foo', slugs: %w[slug_a slug_b] } }

      it { expect(wiki_page.front_matter).to eq(front_matter) }
    end

    context 'the wiki page has front matter' do
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

      context 'the feature flag is off' do
        before do
          disable_front_matter
        end

        it_behaves_like 'a page without front-matter'

        context 'but enabled for the container' do
          before do
            enable_front_matter_for(container)
          end

          it_behaves_like 'a page with front-matter'
        end
      end
    end

    context 'the wiki page does not have front matter' do
      let(:content) { 'My actual content' }

      it_behaves_like 'a page without front-matter'
    end

    context 'the wiki page has fenced blocks, but nothing in them' do
      let(:content) do
        <<~MD
        ---
        ---

        My actual content
        MD
      end

      it_behaves_like 'a page without front-matter'
    end

    context 'the wiki page has invalid YAML type in fenced blocks' do
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

    context 'the wiki page has a disallowed class in fenced block' do
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

    context 'the wiki page has invalid YAML in fenced block' do
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
      include_context 'subject is persisted page', title: 'test initialization'

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
    subject { build_wiki_page }

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
            content: ['is too long (11 Bytes). The maximum size is 10 Bytes.']
          )
        end

        it 'counts content size in bytes rather than characters' do
          subject.attributes[:content] = '💩💩💩'

          expect(subject).not_to be_valid
          expect(subject.errors.messages).to eq(
            content: ['is too long (12 Bytes). The maximum size is 10 Bytes.']
          )
        end
      end

      context 'with an existing page exceeding the limit' do
        include_context 'subject is persisted page'

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
            content: ['is too long (12 Bytes). The maximum size is 11 Bytes.']
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
          subject.title = valid_directory + '/foo'

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

    subject { build_wiki_page }

    context "with valid attributes" do
      it "saves the wiki page" do
        subject.create(attributes)

        expect(wiki.find_page(title)).not_to be_nil
      end

      it "returns true" do
        expect(subject.create(attributes)).to eq(true)
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
  end

  describe "dot in the title" do
    let(:title) { 'Index v1.2.3' }

    describe "#create" do
      subject { build_wiki_page }

      it "saves the wiki page and returns true", :aggregate_failures do
        attributes = { title: title, content: "Home Page", format: "markdown" }

        expect(subject.create(attributes)).to eq(true)
        expect(wiki.find_page(title)).not_to be_nil
      end
    end

    describe '#update' do
      subject { create_wiki_page(title: title) }

      it 'updates the content of the page and returns true', :aggregate_failures do
        expect(subject.update(content: 'new content')).to be_truthy

        page = wiki.find_page(title)

        expect([subject.content, page.content]).to all(eq('new content'))
      end
    end
  end

  describe "#update" do
    let!(:original_title) { subject.title }

    subject { create_wiki_page }

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

        context 'the front matter is too long' do
          let(:new_front_matter) do
            {
              title: generate(:wiki_page_title),
              slugs: Array.new(51).map { FFaker::Lorem.characters(512) }
            }
          end

          it 'raises an error' do
            expect { subject.update(front_matter: new_front_matter) }.to raise_error(described_class::FrontMatterTooLong)
          end
        end

        context 'the front-matter feature flag is not enabled' do
          before do
            disable_front_matter
          end

          it 'does not update the front-matter' do
            content = subject.content
            subject.update(front_matter: { slugs: ['x'] })

            page = wiki.find_page(subject.title)

            expect([subject, page]).to all(have_attributes(front_matter: be_empty, content: content))
          end

          context 'but it is enabled for the container' do
            before do
              enable_front_matter_for(container)
            end

            it_behaves_like 'able to update front-matter'
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
        expect { subject.update(content: 'more content', last_commit_sha: 'xxx') }.to raise_error(WikiPage::PageChangedError)
      end
    end

    context 'when renaming a page' do
      it 'raises an error if the page already exists' do
        existing_page = create_wiki_page

        expect { subject.update(title: existing_page.title, content: 'new_content') }.to raise_error(WikiPage::PageRenameError)
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

        expect { subject.update(title: 'foo/Existing Page', content: 'new_content') }.to raise_error(WikiPage::PageRenameError)
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

      describe 'in subdir' do
        it 'moves the page to the root folder if the title is preceded by /' do
          page = create_wiki_page(title: 'foo/Existing Page')

          expect(page.slug).to eq 'foo/Existing-Page'
          expect(page.update(title: '/Existing Page', content: 'new_content')).to be_truthy
          expect(page.slug).to eq 'Existing-Page'
        end

        it 'does nothing if it has the same title' do
          page = create_wiki_page(title: 'foo/Another Existing Page')

          original_path = page.slug

          expect(page.update(title: 'Another Existing Page', content: 'new_content')).to be_truthy
          expect(page.slug).to eq original_path
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
  end

  describe "#delete" do
    it "deletes the page and returns true", :aggregate_failures do
      page = create_wiki_page

      expect do
        expect(page.delete).to eq(true)
      end.to change { wiki.list_pages.length }.by(-1)
    end
  end

  describe "#versions" do
    let(:subject) { create_wiki_page }

    it "returns an array of all commits for the page" do
      expect do
        3.times { |i| subject.update(content: "content #{i}") }
      end.to change { subject.versions.count }.by(3)
    end
  end

  describe '#title_changed?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:unsaved_page) { build_wiki_page(title: 'test page') }
    let_it_be(:existing_page) { create_wiki_page(title: 'test page') }
    let_it_be(:directory_page) { create_wiki_page(title: 'parent directory/child page') }
    let_it_be(:page_with_special_characters) { create_wiki_page(title: 'test+page') }

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
      subject { build_wiki_page }

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
      include_context 'subject is persisted page'

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

      it 'returns false if only the newline format has changed' do
        expect(subject.page).to receive(:text_data).and_return("foo\nbar")

        subject.attributes[:content] = "foo\r\nbar"

        expect(subject.content_changed?).to be(false)
      end
    end
  end

  describe '#path' do
    it 'returns the path when persisted' do
      existing_page = create_wiki_page(title: 'path test')

      expect(existing_page.path).to eq('path-test.md')
    end

    it 'returns nil when not persisted' do
      unsaved_page = build_wiki_page(title: 'path test')

      expect(unsaved_page.path).to be_nil
    end
  end

  describe '#directory' do
    context 'when the page is at the root directory' do
      include_context 'subject is persisted page', title: 'directory test'

      it 'returns an empty string' do
        expect(subject.directory).to eq('')
      end
    end

    context 'when the page is inside an actual directory' do
      include_context 'subject is persisted page', title: 'dir_1/dir_1_1/directory test'

      it 'returns the full directory hierarchy' do
        expect(subject.directory).to eq('dir_1/dir_1_1')
      end
    end
  end

  describe '#historical?' do
    let!(:container) { create(:project) }

    subject { create_wiki_page }

    let(:wiki) { subject.wiki }
    let(:old_version) { subject.versions.last.id }
    let(:old_page) { wiki.find_page(subject.title, old_version) }
    let(:latest_version) { subject.versions.first.id }
    let(:latest_page) { wiki.find_page(subject.title, latest_version) }

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
      expect(latest_page).to receive(:version) { nil }

      expect(latest_page.historical?).to be_falsy
    end

    it 'returns false when the last version is nil' do
      expect(old_page).to receive(:last_version) { nil }

      expect(old_page.historical?).to be_falsy
    end

    it 'returns false when the version is nil' do
      expect(old_page).to receive(:version) { nil }

      expect(old_page.historical?).to be_falsy
    end
  end

  describe '#persisted?' do
    it 'returns true for a persisted page' do
      expect(create_wiki_page).to be_persisted
    end

    it 'returns false for an unpersisted page' do
      expect(build_wiki_page).not_to be_persisted
    end
  end

  describe '#to_partial_path' do
    it 'returns the relative path to the partial to be used' do
      expect(build_wiki_page.to_partial_path).to eq('../shared/wikis/wiki_page')
    end
  end

  describe '#==' do
    include_context 'subject is persisted page'

    it 'returns true for identical wiki page' do
      expect(subject).to eq(subject)
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
      other_page = create_wiki_page

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
    include_context 'subject is persisted page'

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
    subject { build_wiki_page }

    it 'adds absolute urls for images in the content' do
      subject.attributes[:content] = 'test![WikiPage_Image](/uploads/abc/WikiPage_Image.png)'

      expect(subject.hook_attrs['content']).to eq("test![WikiPage_Image](#{Settings.gitlab.url}/uploads/abc/WikiPage_Image.png)")
    end
  end

  describe '#version_commit_timestamp' do
    context 'for a new page' do
      it 'returns nil' do
        expect(build_wiki_page.version_commit_timestamp).to be_nil
      end
    end

    context 'for page that exists' do
      it 'returns the timestamp of the commit' do
        existing_page = create_wiki_page

        expect(existing_page.version_commit_timestamp).to eq(existing_page.version.commit.committed_date)
      end
    end
  end

  describe '#diffs' do
    include_context 'subject is persisted page'

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
end
