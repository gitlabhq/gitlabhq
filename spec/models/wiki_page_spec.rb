require "spec_helper"

describe WikiPage do
  let(:project) { create(:project) }
  let(:user) { project.owner }
  let(:wiki) { ProjectWiki.new(project, user) }

  subject { described_class.new(wiki) }

  describe '.group_by_directory' do
    context 'when there are no pages' do
      it 'returns an empty array' do
        expect(described_class.group_by_directory(nil)).to eq([])
        expect(described_class.group_by_directory([])).to eq([])
      end
    end

    context 'when there are pages' do
      before do
        create_page('dir_1/dir_1_1/page_3', 'content')
        create_page('dir_1/page_2', 'content')
        create_page('dir_2/page_5', 'content')
        create_page('dir_2/page_4', 'content')
        create_page('page_1', 'content')
      end
      let(:page_1) { wiki.find_page('page_1') }
      let(:dir_1) do
        WikiDirectory.new('dir_1', [wiki.find_page('dir_1/page_2')])
      end
      let(:dir_1_1) do
        WikiDirectory.new('dir_1/dir_1_1', [wiki.find_page('dir_1/dir_1_1/page_3')])
      end
      let(:dir_2) do
        pages = [wiki.find_page('dir_2/page_5'),
                 wiki.find_page('dir_2/page_4')]
        WikiDirectory.new('dir_2', pages)
      end

      it 'returns an array with pages and directories' do
        expected_grouped_entries = [page_1, dir_1, dir_1_1, dir_2]

        grouped_entries = described_class.group_by_directory(wiki.pages)

        grouped_entries.each_with_index do |page_or_dir, i|
          expected_page_or_dir = expected_grouped_entries[i]
          expected_slugs = get_slugs(expected_page_or_dir)
          slugs = get_slugs(page_or_dir)

          expect(slugs).to match_array(expected_slugs)
        end
      end

      it 'returns an array sorted by alphabetical position' do
        # Directories and pages within directories are sorted alphabetically.
        # Pages at root come before everything.
        expected_order = ['page_1', 'dir_1/page_2', 'dir_1/dir_1_1/page_3',
                          'dir_2/page_4', 'dir_2/page_5']

        grouped_entries = described_class.group_by_directory(wiki.pages)

        actual_order =
          grouped_entries.map do |page_or_dir|
            get_slugs(page_or_dir)
          end
          .flatten
        expect(actual_order).to eq(expected_order)
      end
    end
  end

  describe '.unhyphenize' do
    it 'removes hyphens from a name' do
      name = 'a-name--with-hyphens'

      expect(described_class.unhyphenize(name)).to eq('a name with hyphens')
    end
  end

  describe "#initialize" do
    context "when initialized with an existing gollum page" do
      before do
        create_page("test page", "test content")
        @page = wiki.wiki.page(title: "test page")
        @wiki_page = described_class.new(wiki, @page, true)
      end

      it "sets the slug attribute" do
        expect(@wiki_page.slug).to eq("test-page")
      end

      it "sets the title attribute" do
        expect(@wiki_page.title).to eq("test page")
      end

      it "sets the formatted content attribute" do
        expect(@wiki_page.content).to eq("test content")
      end

      it "sets the format attribute" do
        expect(@wiki_page.format).to eq(:markdown)
      end

      it "sets the message attribute" do
        expect(@wiki_page.message).to eq("test commit")
      end

      it "sets the version attribute" do
        expect(@wiki_page.version).to be_a Gitlab::Git::WikiPageVersion
      end
    end
  end

  describe "validations" do
    before do
      subject.attributes = { title: 'title', content: 'content' }
    end

    it "validates presence of title" do
      subject.attributes.delete(:title)
      expect(subject.valid?).to be_falsey
    end

    it "validates presence of content" do
      subject.attributes.delete(:content)
      expect(subject.valid?).to be_falsey
    end
  end

  before do
    @wiki_attr = { title: "Index", content: "Home Page", format: "markdown" }
  end

  describe "#create" do
    after do
      destroy_page("Index")
    end

    context "with valid attributes" do
      it "saves the wiki page" do
        subject.create(@wiki_attr)
        expect(wiki.find_page("Index")).not_to be_nil
      end

      it "returns true" do
        expect(subject.create(@wiki_attr)).to eq(true)
      end
    end
  end

  describe "dot in the title" do
    let(:title) { 'Index v1.2.3' }

    before do
      @wiki_attr = { title: title, content: "Home Page", format: "markdown" }
    end

    describe "#create" do
      after do
        destroy_page(title)
      end

      context "with valid attributes" do
        it "saves the wiki page" do
          subject.create(@wiki_attr)
          expect(wiki.find_page(title)).not_to be_nil
        end

        it "returns true" do
          expect(subject.create(@wiki_attr)).to eq(true)
        end
      end
    end

    describe "#update" do
      before do
        create_page(title, "content")
        @page = wiki.find_page(title)
      end

      it "updates the content of the page" do
        @page.update(content: "new content")
        @page = wiki.find_page(title)
      end

      it "returns true" do
        expect(@page.update(content: "more content")).to be_truthy
      end
    end
  end

  describe '#create' do
    shared_examples 'create method' do
      context 'with valid attributes' do
        it 'raises an error if a page with the same path already exists' do
          create_page('New Page', 'content')
          create_page('foo/bar', 'content')
          expect { create_page('New Page', 'other content') }.to raise_error Gitlab::Git::Wiki::DuplicatePageError
          expect { create_page('foo/bar', 'other content') }.to raise_error Gitlab::Git::Wiki::DuplicatePageError

          destroy_page('New Page')
          destroy_page('bar', 'foo')
        end

        it 'if the title is preceded by a / it is removed' do
          create_page('/New Page', 'content')

          expect(wiki.find_page('New Page')).not_to be_nil

          destroy_page('New Page')
        end
      end
    end

    context 'when Gitaly is enabled' do
      it_behaves_like 'create method'
    end

    context 'when Gitaly is disabled', :skip_gitaly_mock do
      it_behaves_like 'create method'
    end
  end

  describe "#update" do
    shared_examples 'update method' do
      before do
        create_page("Update", "content")
        @page = wiki.find_page("Update")
      end

      after do
        destroy_page(@page.title, @page.directory)
      end

      context "with valid attributes" do
        it "updates the content of the page" do
          new_content = "new content"

          @page.update(content: new_content)
          @page = wiki.find_page("Update")

          expect(@page.content).to eq("new content")
        end

        it "updates the title of the page" do
          new_title = "Index v.1.2.4"

          @page.update(title: new_title)
          @page = wiki.find_page(new_title)

          expect(@page.title).to eq(new_title)
        end

        it "returns true" do
          expect(@page.update(content: "more content")).to be_truthy
        end
      end

      context 'with same last commit sha' do
        it 'returns true' do
          expect(@page.update(content: 'more content', last_commit_sha: @page.last_commit_sha)).to be_truthy
        end
      end

      context 'with different last commit sha' do
        it 'raises exception' do
          expect { @page.update(content: 'more content', last_commit_sha: 'xxx') }.to raise_error(WikiPage::PageChangedError)
        end
      end

      context 'when renaming a page' do
        it 'raises an error if the page already exists' do
          create_page('Existing Page', 'content')

          expect { @page.update(title: 'Existing Page', content: 'new_content') }.to raise_error(WikiPage::PageRenameError)
          expect(@page.title).to eq 'Update'
          expect(@page.content).to eq 'new_content'

          destroy_page('Existing Page')
        end

        it 'updates the content and rename the file' do
          new_title = 'Renamed Page'
          new_content = 'updated content'

          expect(@page.update(title: new_title, content: new_content)).to be_truthy

          @page = wiki.find_page(new_title)

          expect(@page).not_to be_nil
          expect(@page.content).to eq new_content
        end
      end

      context 'when moving a page' do
        it 'raises an error if the page already exists' do
          create_page('foo/Existing Page', 'content')

          expect { @page.update(title: 'foo/Existing Page', content: 'new_content') }.to raise_error(WikiPage::PageRenameError)
          expect(@page.title).to eq 'Update'
          expect(@page.content).to eq 'new_content'

          destroy_page('Existing Page', 'foo')
        end

        it 'updates the content and moves the file' do
          new_title = 'foo/Other Page'
          new_content = 'new_content'

          expect(@page.update(title: new_title, content: new_content)).to be_truthy

          page = wiki.find_page(new_title)

          expect(page).not_to be_nil
          expect(page.content).to eq new_content
        end

        context 'in subdir' do
          before do
            create_page('foo/Existing Page', 'content')
            @page = wiki.find_page('foo/Existing Page')
          end

          it 'moves the page to the root folder if the title is preceded by /', :skip_gitaly_mock do
            expect(@page.slug).to eq 'foo/Existing-Page'
            expect(@page.update(title: '/Existing Page', content: 'new_content')).to be_truthy
            expect(@page.slug).to eq 'Existing-Page'
          end

          it 'does nothing if it has the same title' do
            original_path = @page.slug

            expect(@page.update(title: 'Existing Page', content: 'new_content')).to be_truthy
            expect(@page.slug).to eq original_path
          end
        end

        context 'in root dir' do
          it 'does nothing if the title is preceded by /' do
            original_path = @page.slug

            expect(@page.update(title: '/Update', content: 'new_content')).to be_truthy
            expect(@page.slug).to eq original_path
          end
        end
      end

      context "with invalid attributes" do
        it 'aborts update if title blank' do
          expect(@page.update(title: '', content: 'new_content')).to be_falsey
          expect(@page.content).to eq 'new_content'

          page = wiki.find_page('Update')
          expect(page.content).to eq 'content'

          @page.title = 'Update'
        end
      end
    end

    context 'when Gitaly is enabled' do
      it_behaves_like 'update method'
    end

    context 'when Gitaly is disabled', :skip_gitaly_mock do
      it_behaves_like 'update method'
    end
  end

  describe "#destroy" do
    before do
      create_page("Delete Page", "content")
      @page = wiki.find_page("Delete Page")
    end

    it "deletes the page" do
      @page.delete
      expect(wiki.pages).to be_empty
    end

    it "returns true" do
      expect(@page.delete).to eq(true)
    end
  end

  describe "#versions" do
    shared_examples 'wiki page versions' do
      let(:page) { wiki.find_page("Update") }

      before do
        create_page("Update", "content")
      end

      after do
        destroy_page("Update")
      end

      it "returns an array of all commits for the page" do
        3.times { |i| page.update(content: "content #{i}") }

        expect(page.versions.count).to eq(4)
      end

      it 'returns instances of WikiPageVersion' do
        expect(page.versions).to all( be_a(Gitlab::Git::WikiPageVersion) )
      end
    end

    context 'when Gitaly is enabled' do
      it_behaves_like 'wiki page versions'
    end

    context 'when Gitaly is disabled', :disable_gitaly do
      it_behaves_like 'wiki page versions'
    end
  end

  describe "#title" do
    before do
      create_page("Title", "content")
      @page = wiki.find_page("Title")
    end

    after do
      destroy_page("Title")
    end

    it "replaces a hyphen to a space" do
      @page.title = "Import-existing-repositories-into-GitLab"
      expect(@page.title).to eq("Import existing repositories into GitLab")
    end

    it 'unescapes html' do
      @page.title = 'foo &amp; bar'

      expect(@page.title).to eq('foo & bar')
    end
  end

  describe '#directory' do
    context 'when the page is at the root directory' do
      it 'returns an empty string' do
        create_page('file', 'content')
        page = wiki.find_page('file')

        expect(page.directory).to eq('')
      end
    end

    context 'when the page is inside an actual directory' do
      it 'returns the full directory hierarchy' do
        create_page('dir_1/dir_1_1/file', 'content')
        page = wiki.find_page('dir_1/dir_1_1/file')

        expect(page.directory).to eq('dir_1/dir_1_1')
      end
    end
  end

  describe '#historical?' do
    before do
      create_page('Update', 'content')
      @page = wiki.find_page('Update')
      3.times { |i| @page.update(content: "content #{i}") }
    end

    after do
      destroy_page('Update')
    end

    it 'returns true when requesting an old version' do
      old_version = @page.versions.last.id
      old_page = wiki.find_page('Update', old_version)

      expect(old_page.historical?).to eq true
    end

    it 'returns false when requesting latest version' do
      latest_version = @page.versions.first.id
      latest_page = wiki.find_page('Update', latest_version)

      expect(latest_page.historical?).to eq false
    end

    it 'returns false when version is nil' do
      latest_page = wiki.find_page('Update', nil)

      expect(latest_page.historical?).to eq false
    end
  end

  describe '#to_partial_path' do
    it 'returns the relative path to the partial to be used' do
      page = build(:wiki_page)

      expect(page.to_partial_path).to eq('projects/wikis/wiki_page')
    end
  end

  describe '#==' do
    let(:original_wiki_page) { create(:wiki_page) }

    it 'returns true for identical wiki page' do
      expect(original_wiki_page).to eq(original_wiki_page)
    end

    it 'returns false for updated wiki page' do
      updated_wiki_page = original_wiki_page.update(content: "Updated content")
      expect(original_wiki_page).not_to eq(updated_wiki_page)
    end
  end

  describe '#last_commit_sha' do
    before do
      create_page("Update", "content")
      @page = wiki.find_page("Update")
    end

    after do
      destroy_page("Update")
    end

    it 'returns commit sha' do
      expect(@page.last_commit_sha).to eq @page.last_version.sha
    end

    it 'is changed after page updated' do
      last_commit_sha_before_update = @page.last_commit_sha

      @page.update(content: "new content")
      @page = wiki.find_page("Update")

      expect(@page.last_commit_sha).not_to eq last_commit_sha_before_update
    end
  end

  describe '#formatted_content' do
    shared_examples 'fetching page formatted content' do
      it 'returns processed content of the page' do
        subject.create({ title: "RDoc", content: "*bold*", format: "rdoc" })
        page = wiki.find_page('RDoc')

        expect(page.formatted_content).to eq("\n<p><strong>bold</strong></p>\n")

        destroy_page('RDoc')
      end
    end

    context 'when Gitaly wiki_page_formatted_data is enabled' do
      it_behaves_like 'fetching page formatted content'
    end

    context 'when Gitaly wiki_page_formatted_data is disabled', :disable_gitaly do
      it_behaves_like 'fetching page formatted content'
    end
  end

  private

  def remove_temp_repo(path)
    FileUtils.rm_rf path
  end

  def commit_details
    Gitlab::Git::Wiki::CommitDetails.new(user.name, user.email, "test commit")
  end

  def create_page(name, content)
    wiki.wiki.write_page(name, :markdown, content, commit_details)
  end

  def destroy_page(title, dir = '')
    page = wiki.wiki.page(title: title, dir: dir)
    wiki.delete_page(page, "test commit")
  end

  def get_slugs(page_or_dir)
    if page_or_dir.is_a? WikiPage
      [page_or_dir.slug]
    else
      page_or_dir.pages.present? ? page_or_dir.pages.map(&:slug) : []
    end
  end
end
