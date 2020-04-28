# frozen_string_literal: true

RSpec.shared_examples 'wiki model' do
  let_it_be(:user) { create(:user, :commit_email) }
  let(:wiki_container) { raise NotImplementedError }
  let(:wiki_container_without_repo) { raise NotImplementedError }
  let(:wiki) { described_class.new(wiki_container, user) }
  let(:commit) { subject.repository.head_commit }

  subject { wiki }

  it_behaves_like 'model with repository' do
    let(:container) { wiki }
    let(:stubbed_container) { described_class.new(wiki_container_without_repo, user) }
    let(:expected_full_path) { "#{container.container.full_path}.wiki" }
    let(:expected_web_url_path) { "#{container.container.web_url(only_path: true).sub(%r{^/}, '')}/-/wikis/home" }
  end

  describe '#repository' do
    it 'returns a wiki repository' do
      expect(subject.repository.repo_type).to be_wiki
    end
  end

  describe '#full_path' do
    it 'returns the container path with the .wiki extension' do
      expect(subject.full_path).to eq(wiki_container.full_path + '.wiki')
    end
  end

  describe '#wiki_base_path' do
    it 'returns the wiki base path' do
      expect(subject.wiki_base_path).to eq("#{wiki_container.web_url(only_path: true)}/-/wikis")
    end
  end

  describe '#wiki' do
    it 'contains a Gitlab::Git::Wiki instance' do
      expect(subject.wiki).to be_a Gitlab::Git::Wiki
    end

    it 'creates a new wiki repo if one does not yet exist' do
      expect(subject.create_page('index', 'test content')).to be_truthy
    end

    it 'creates a new wiki repo with a default commit message' do
      expect(subject.create_page('index', 'test content', :markdown, '')).to be_truthy

      page = subject.find_page('index')

      expect(page.last_version.message).to eq("#{user.username} created page: index")
    end

    context 'when the repository cannot be created' do
      let(:wiki_container) { wiki_container_without_repo }

      before do
        expect(subject.repository).to receive(:create_if_not_exists) { false }
      end

      it 'raises CouldNotCreateWikiError' do
        expect { subject.wiki }.to raise_exception(Wiki::CouldNotCreateWikiError)
      end
    end
  end

  describe '#empty?' do
    context 'when the wiki repository is empty' do
      it 'returns true' do
        expect(subject.empty?).to be(true)
      end
    end

    context 'when the wiki has pages' do
      before do
        subject.create_page('index', 'This is an awesome new Gollum Wiki')
        subject.create_page('another-page', 'This is another page')
      end

      describe '#empty?' do
        it 'returns false' do
          expect(subject.empty?).to be(false)
        end

        it 'only instantiates a Wiki page once' do
          expect(WikiPage).to receive(:new).once.and_call_original

          subject.empty?
        end
      end
    end
  end

  describe '#list_pages' do
    let(:wiki_pages) { subject.list_pages }

    before do
      subject.create_page('index', 'This is an index')
      subject.create_page('index2', 'This is an index2')
      subject.create_page('an index3', 'This is an index3')
    end

    it 'returns an array of WikiPage instances' do
      expect(wiki_pages).to be_present
      expect(wiki_pages).to all(be_a(WikiPage))
    end

    it 'does not load WikiPage content by default' do
      wiki_pages.each do |page|
        expect(page.content).to be_empty
      end
    end

    it 'returns all pages by default' do
      expect(wiki_pages.count).to eq(3)
    end

    context 'with limit option' do
      it 'returns limited set of pages' do
        expect(subject.list_pages(limit: 1).count).to eq(1)
      end
    end

    context 'with sorting options' do
      it 'returns pages sorted by title by default' do
        pages = ['an index3', 'index', 'index2']

        expect(subject.list_pages.map(&:title)).to eq(pages)
        expect(subject.list_pages(direction: 'desc').map(&:title)).to eq(pages.reverse)
      end

      it 'returns pages sorted by created_at' do
        pages = ['index', 'index2', 'an index3']

        expect(subject.list_pages(sort: 'created_at').map(&:title)).to eq(pages)
        expect(subject.list_pages(sort: 'created_at', direction: 'desc').map(&:title)).to eq(pages.reverse)
      end
    end

    context 'with load_content option' do
      let(:pages) { subject.list_pages(load_content: true) }

      it 'loads WikiPage content' do
        expect(pages.first.content).to eq('This is an index3')
        expect(pages.second.content).to eq('This is an index')
        expect(pages.third.content).to eq('This is an index2')
      end
    end
  end

  describe '#sidebar_entries' do
    before do
      (1..5).each { |i| create(:wiki_page, wiki: wiki, title: "my page #{i}") }
      (6..10).each { |i| create(:wiki_page, wiki: wiki, title: "parent/my page #{i}") }
      (11..15).each { |i| create(:wiki_page, wiki: wiki, title: "grandparent/parent/my page #{i}") }
    end

    def total_pages(entries)
      entries.sum do |entry|
        entry.is_a?(WikiDirectory) ? entry.pages.size : 1
      end
    end

    context 'when the number of pages does not exceed the limit' do
      it 'returns all pages grouped by directory and limited is false' do
        entries, limited = subject.sidebar_entries

        expect(entries.size).to be(7)
        expect(total_pages(entries)).to be(15)
        expect(limited).to be(false)
      end
    end

    context 'when the number of pages exceeds the limit' do
      before do
        create(:wiki_page, wiki: wiki, title: 'my page 16')
      end

      it 'returns 15 pages grouped by directory and limited is true' do
        entries, limited = subject.sidebar_entries

        expect(entries.size).to be(8)
        expect(total_pages(entries)).to be(15)
        expect(limited).to be(true)
      end
    end
  end

  describe '#find_page' do
    before do
      subject.create_page('index page', 'This is an awesome Gollum Wiki')
    end

    it 'returns the latest version of the page if it exists' do
      page = subject.find_page('index page')

      expect(page.title).to eq('index page')
    end

    it 'returns nil if the page does not exist' do
      expect(subject.find_page('non-existent')).to eq(nil)
    end

    it 'can find a page by slug' do
      page = subject.find_page('index-page')

      expect(page.title).to eq('index page')
    end

    it 'returns a WikiPage instance' do
      page = subject.find_page('index page')

      expect(page).to be_a WikiPage
    end

    context 'pages with multibyte-character title' do
      before do
        subject.create_page('autre pagé', "C'est un génial Gollum Wiki")
      end

      it 'can find a page by slug' do
        page = subject.find_page('autre pagé')

        expect(page.title).to eq('autre pagé')
      end
    end

    context 'pages with invalidly-encoded content' do
      before do
        subject.create_page('encoding is fun', "f\xFCr".b)
      end

      it 'can find the page' do
        page = subject.find_page('encoding is fun')

        expect(page.content).to eq('fr')
      end
    end
  end

  describe '#find_sidebar' do
    before do
      subject.create_page(described_class::SIDEBAR, 'This is an awesome Sidebar')
    end

    it 'finds the page defined as _sidebar' do
      page = subject.find_sidebar

      expect(page.content).to eq('This is an awesome Sidebar')
    end
  end

  describe '#find_file' do
    let(:image) { File.open(Rails.root.join('spec', 'fixtures', 'big-image.png')) }

    before do
      subject.wiki # Make sure the wiki repo exists

      subject.repository.create_file(user, 'image.png', image, branch_name: subject.default_branch, message: 'add image')
    end

    it 'returns the latest version of the file if it exists' do
      file = subject.find_file('image.png')

      expect(file.mime_type).to eq('image/png')
    end

    it 'returns nil if the page does not exist' do
      expect(subject.find_file('non-existent')).to eq(nil)
    end

    it 'returns a Gitlab::Git::WikiFile instance' do
      file = subject.find_file('image.png')

      expect(file).to be_a Gitlab::Git::WikiFile
    end

    it 'returns the whole file' do
      file = subject.find_file('image.png')
      image.rewind

      expect(file.raw_data.b).to eq(image.read.b)
    end
  end

  describe '#create_page' do
    it 'creates a new wiki page' do
      expect(subject.create_page('test page', 'this is content')).not_to eq(false)
      expect(subject.list_pages.count).to eq(1)
    end

    it 'returns false when a duplicate page exists' do
      subject.create_page('test page', 'content')

      expect(subject.create_page('test page', 'content')).to eq(false)
    end

    it 'stores an error message when a duplicate page exists' do
      2.times { subject.create_page('test page', 'content') }

      expect(subject.error_message).to match(/Duplicate page:/)
    end

    it 'sets the correct commit message' do
      subject.create_page('test page', 'some content', :markdown, 'commit message')

      expect(subject.list_pages.first.page.version.message).to eq('commit message')
    end

    it 'sets the correct commit email' do
      subject.create_page('test page', 'content')

      expect(user.commit_email).not_to eq(user.email)
      expect(commit.author_email).to eq(user.commit_email)
      expect(commit.committer_email).to eq(user.commit_email)
    end

    it 'updates container activity' do
      expect(subject).to receive(:update_container_activity)

      subject.create_page('Test Page', 'This is content')
    end
  end

  describe '#update_page' do
    let(:page) { create(:wiki_page, wiki: subject, title: 'update-page') }

    def update_page
      subject.update_page(
        page.page,
        content: 'some other content',
        format: :markdown,
        message: 'updated page'
      )
    end

    it 'updates the content of the page' do
      update_page
      page = subject.find_page('update-page')

      expect(page.raw_content).to eq('some other content')
    end

    it 'sets the correct commit message' do
      update_page
      page = subject.find_page('update-page')

      expect(page.version.message).to eq('updated page')
    end

    it 'sets the correct commit email' do
      update_page

      expect(user.commit_email).not_to eq(user.email)
      expect(commit.author_email).to eq(user.commit_email)
      expect(commit.committer_email).to eq(user.commit_email)
    end

    it 'updates container activity' do
      page

      expect(subject).to receive(:update_container_activity)

      update_page
    end
  end

  describe '#delete_page' do
    let(:page) { create(:wiki_page, wiki: wiki) }

    it 'deletes the page' do
      subject.delete_page(page)

      expect(subject.list_pages.count).to eq(0)
    end

    it 'sets the correct commit email' do
      subject.delete_page(page)

      expect(user.commit_email).not_to eq(user.email)
      expect(commit.author_email).to eq(user.commit_email)
      expect(commit.committer_email).to eq(user.commit_email)
    end

    it 'updates container activity' do
      page

      expect(subject).to receive(:update_container_activity)

      subject.delete_page(page)
    end
  end

  describe '#ensure_repository' do
    context 'if the repository exists' do
      it 'does not create the repository' do
        expect(subject.repository.exists?).to eq(true)
        expect(subject.repository.raw).not_to receive(:create_repository)

        subject.ensure_repository
      end
    end

    context 'if the repository does not exist' do
      let(:wiki_container) { wiki_container_without_repo }

      it 'creates the repository' do
        expect(subject.repository.exists?).to eq(false)

        subject.ensure_repository

        expect(subject.repository.exists?).to eq(true)
      end
    end
  end

  describe '#hook_attrs' do
    it 'returns a hash with values' do
      expect(subject.hook_attrs).to be_a Hash
      expect(subject.hook_attrs.keys).to contain_exactly(:web_url, :git_ssh_url, :git_http_url, :path_with_namespace, :default_branch)
    end
  end
end
