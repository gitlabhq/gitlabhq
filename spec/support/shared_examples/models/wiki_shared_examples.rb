# frozen_string_literal: true

RSpec.shared_examples 'wiki model' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user, :commit_email) }

  let(:wiki_container) { raise NotImplementedError }
  let(:wiki_container_without_repo) { raise NotImplementedError }
  let(:wiki_lfs_enabled) { false }
  let(:wiki) { described_class.new(wiki_container, user) }
  let(:commit) { subject.repository.head_commit }

  subject { wiki }

  it 'VALID_USER_MARKUPS contains all valid markups' do
    expect(described_class::VALID_USER_MARKUPS.keys).to match_array(%i(markdown rdoc asciidoc org))
  end

  it 'container class includes HasWiki' do
    # NOTE: This is not enforced at runtime, since we also need to support Geo::DeletedProject
    expect(wiki_container).to be_kind_of(HasWiki)
    expect(wiki_container_without_repo).to be_kind_of(HasWiki)
  end

  it_behaves_like 'model with repository' do
    let(:container) { wiki }
    let(:stubbed_container) { described_class.new(wiki_container_without_repo, user) }
    let(:expected_full_path) { "#{container.container.full_path}.wiki" }
    let(:expected_web_url_path) { "#{container.container.web_url(only_path: true).sub(%r{^/}, '')}/-/wikis/home" }
    let(:expected_lfs_enabled) { wiki_lfs_enabled }
  end

  describe '.container_class' do
    it 'is set to the container class' do
      expect(described_class.container_class).to eq(wiki_container.class)
    end
  end

  describe '.find_by_id' do
    it 'returns a wiki instance if the container is found' do
      wiki = described_class.find_by_id(wiki_container.id)

      expect(wiki).to be_a(described_class)
      expect(wiki.container).to eq(wiki_container)
    end

    it 'returns nil if the container is not found' do
      expect(described_class.find_by_id(-1)).to be_nil
    end
  end

  describe '#initialize' do
    it 'accepts a valid user' do
      expect do
        described_class.new(wiki_container, user)
      end.not_to raise_error
    end

    it 'accepts a blank user' do
      expect do
        described_class.new(wiki_container, nil)
      end.not_to raise_error
    end

    it 'raises an error for invalid users' do
      expect do
        described_class.new(wiki_container, Object.new)
      end.to raise_error(ArgumentError, 'user must be a User, got Object')
    end
  end

  describe '#run_after_commit' do
    it 'delegates to the container' do
      expect(wiki_container).to receive(:run_after_commit)

      wiki.run_after_commit
    end
  end

  describe '#==' do
    it 'returns true for wikis from the same container' do
      expect(wiki).to eq(described_class.new(wiki_container))
    end

    it 'returns false for wikis from different containers' do
      expect(wiki).not_to eq(described_class.new(wiki_container_without_repo))
    end
  end

  describe '#id' do
    it 'returns the ID of the container' do
      expect(wiki.id).to eq(wiki_container.id)
    end
  end

  describe '#has_home_page?' do
    context 'when home page exists' do
      before do
        wiki.repository.create_file(
          user,
          'home.md',
          'home file',
          branch_name: wiki.default_branch,
          message: "created home page",
          author_email: user.email,
          author_name: user.name
        )
      end

      it 'returns true' do
        expect(wiki.has_home_page?).to eq(true)
      end

      it 'returns false when #find_page raise an error' do
        allow(wiki)
          .to receive(:find_page)
          .and_raise(StandardError)

        expect(wiki.has_home_page?).to eq(false)
      end
    end

    context 'when home page does not exist' do
      it 'returns false' do
        expect(wiki.has_home_page?).to eq(false)
      end
    end
  end

  describe '#to_global_id' do
    it 'returns a global ID' do
      expect(wiki.to_global_id.to_s).to eq("gid://gitlab/#{wiki.class.name}/#{wiki.id}")
    end
  end

  describe '#repository' do
    it 'returns a wiki repository' do
      expect(subject.repository.repo_type).to be_wiki
      expect(subject.repository.container).to be(subject)
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

    it 'includes the relative URL root' do
      allow(Rails.application.routes).to receive(:default_url_options).and_return(script_name: '/root')

      expect(subject.wiki_base_path).to start_with('/root/')
      expect(subject.wiki_base_path).not_to start_with('/root/root')
    end
  end

  describe '#empty?' do
    context 'when the wiki repository is empty' do
      it 'returns true' do
        expect(subject.empty?).to be(true)
      end

      context 'when the repository does not exist' do
        let(:wiki_container) { wiki_container_without_repo }

        it 'returns true and does not create the repo' do
          expect(subject.empty?).to be(true)
          expect(wiki.repository_exists?).to be false
        end
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
      end
    end
  end

  describe '#list_pages' do
    shared_examples 'wiki model #list_pages' do
      let(:wiki_pages) { subject.list_pages }

      before do
        # The order is intentional
        subject.create_page('index2', 'This is an index2')
        subject.create_page('index', 'This is an index')
        subject.create_page('index3', 'This is an index3')
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
          expect(
            subject.list_pages(limit: 1).map(&:title)
          ).to eql(%w[index])
        end

        it 'returns all set of pages if limit is more than the total pages' do
          expect(subject.list_pages(limit: 4).count).to eq(3)
        end

        it 'returns all set of pages if limit is 0' do
          expect(subject.list_pages(limit: 0).count).to eq(3)
        end
      end

      context 'with offset option' do
        it 'returns offset-ed set of pages' do
          expect(
            subject.list_pages(offset: 1).map(&:title)
          ).to eq(%w[index2 index3])

          expect(
            subject.list_pages(offset: 2).map(&:title)
          ).to eq(["index3"])
          expect(subject.list_pages(offset: 3).count).to eq(0)
          expect(subject.list_pages(offset: 4).count).to eq(0)
        end

        it 'returns all set of pages if offset is 0' do
          expect(subject.list_pages(offset: 0).count).to eq(3)
        end

        it 'can combines with limit' do
          expect(
            subject.list_pages(offset: 1, limit: 1).map(&:title)
          ).to eq(["index2"])
        end
      end

      context 'with sorting options' do
        it 'returns pages sorted by title by default' do
          pages = %w[index index2 index3]

          expect(subject.list_pages.map(&:title)).to eq(pages)
          expect(subject.list_pages(direction: 'desc').map(&:title)).to eq(pages.reverse)
        end
      end

      context 'with load_content option' do
        let(:pages) { subject.list_pages(load_content: true) }

        it 'loads WikiPage content' do
          expect(pages.first.content).to eq('This is an index')
          expect(pages.second.content).to eq('This is an index2')
          expect(pages.third.content).to eq('This is an index3')
        end
      end
    end

    it_behaves_like 'wiki model #list_pages'
  end

  describe '#sidebar_entries' do
    before do
      (1..5).each { |i| create(:wiki_page, wiki: wiki, title: "my page #{i}") }
      (6..10).each { |i| create(:wiki_page, wiki: wiki, title: "parent/my page #{i}") }
      (11..15).each { |i| create(:wiki_page, wiki: wiki, title: "grandparent/parent/my page #{i}") }
    end

    def total_pages(entries)
      entries.sum do |entry|
        entry.is_a?(WikiDirectory) ? total_pages(entry.entries) : 1
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
    shared_examples 'wiki model #find_page' do
      before do
        subject.create_page('index page', 'This is an awesome Gollum Wiki')
      end

      it 'returns the latest version of the page if it exists' do
        page = subject.find_page('index page')

        expect(page.title).to eq('index page')
      end

      it 'returns nil if the page or version does not exist' do
        expect(subject.find_page('non-existent')).to be_nil
        expect(subject.find_page('index page', 'non-existent')).to be_nil
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

      context "wiki repository's default branch is updated" do
        before do
          old_default_branch = wiki.default_branch
          subject.create_page('page in updated default branch', 'content')
          subject.repository.add_branch(user, 'another_branch', old_default_branch)
          subject.repository.rm_branch(user, old_default_branch)
          subject.repository.expire_status_cache
        end

        it 'returns the page in the updated default branch' do
          wiki = described_class.new(wiki_container, user)
          page = wiki.find_page('page in updated default branch')

          expect(wiki.default_branch).to eql('another_branch')
          expect(page.title).to eq('page in updated default branch')
        end
      end

      context "wiki repository's HEAD is updated" do
        before do
          subject.create_page('page in updated HEAD', 'content')
          subject.repository.add_branch(user, 'another_branch', subject.default_branch)
          subject.repository.change_head('another_branch')
          subject.repository.expire_status_cache
        end

        it 'returns the page in the new HEAD' do
          wiki = described_class.new(wiki_container, user)
          page = subject.find_page('page in updated HEAD')

          expect(wiki.default_branch).to eql('another_branch')
          expect(page.title).to eq('page in updated HEAD')
        end
      end

      context 'pages with relative paths' do
        where(:path, :title) do
          [
            ['~hello.md', '~Hello'],
            ['hello~world.md', 'Hello~World'],
            ['~~~hello.md', '~~~Hello'],
            ['~/hello.md', '~/Hello'],
            ['hello.md', '/Hello'],
            ['hello.md', '../Hello'],
            ['hello.md', './Hello'],
            ['dir/hello.md', '/dir/Hello']
          ]
        end

        with_them do
          before do
            wiki.repository.create_file(
              user, path, "content of wiki file",
              branch_name: wiki.default_branch,
              message: "created page #{path}",
              author_email: user.email,
              author_name: user.name
            )
          end

          it "can find page with `#{params[:title]}` title" do
            page = subject.find_page(title)

            expect(page.content).to eq("content of wiki file")
          end
        end
      end

      context 'pages with different file extensions' do
        where(:extension, :path, :title) do
          [
            [:md, "wiki-markdown.md", "wiki markdown"],
            [:markdown, "wiki-markdown-2.md", "wiki markdown 2"],
            [:rdoc, "wiki-rdoc.rdoc", "wiki rdoc"],
            [:asciidoc, "wiki-asciidoc.asciidoc", "wiki asciidoc"],
            [:adoc, "wiki-asciidoc-2.adoc", "wiki asciidoc 2"],
            [:org, "wiki-org.org", "wiki org"],
            [:textile, "wiki-textile.textile", "wiki textile"],
            [:creole, "wiki-creole.creole", "wiki creole"],
            [:rest, "wiki-rest.rest", "wiki rest"],
            [:rst, "wiki-rest-2.rst", "wiki rest 2"],
            [:mediawiki, "wiki-mediawiki.mediawiki", "wiki mediawiki"],
            [:wiki, "wiki-mediawiki-2.wiki", "wiki mediawiki 2"],
            [:pod, "wiki-pod.pod", "wiki pod"],
            [:text, "wiki-text.txt", "wiki text"]
          ]
        end

        with_them do
          before do
            wiki.repository.create_file(
              user, path, "content of wiki file",
              branch_name: wiki.default_branch,
              message: "created page #{path}",
              author_email: user.email,
              author_name: user.name
            )
          end

          it "can find page with #{params[:extension]} extension" do
            page = subject.find_page(title)

            expect(page.content).to eq("content of wiki file")
          end
        end
      end
    end

    context 'find page with normal repository RPCs' do
      it_behaves_like 'wiki model #find_page'
    end
  end

  describe '#find_sidebar' do
    shared_examples 'wiki model #find_sidebar' do
      before do
        subject.create_page(described_class::SIDEBAR, 'This is an awesome Sidebar')
      end

      it 'finds the page defined as _sidebar' do
        page = subject.find_sidebar

        expect(page.content).to eq('This is an awesome Sidebar')
      end
    end

    context 'find sidebar with normal repository RPCs' do
      it_behaves_like 'wiki model #find_sidebar'
    end
  end

  describe '#find_file' do
    let(:image) { File.open(Rails.root.join('spec', 'fixtures', 'big-image.png')) }

    before do
      subject.create_wiki_repository # Make sure the wiki repo exists

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

    context 'when load_content is disabled' do
      it 'includes the file data in the Gitlab::Git::WikiFile' do
        file = subject.find_file('image.png', load_content: false)

        expect(file.raw_data).to be_empty
      end
    end

    context "wiki repository's default branch is updated" do
      before do
        old_default_branch = wiki.default_branch
        subject.repository.add_branch(user, 'another_branch', old_default_branch)
        subject.repository.rm_branch(user, old_default_branch)
        subject.repository.expire_status_cache
      end

      it 'returns the page in the updated default branch' do
        wiki = described_class.new(wiki_container, user)
        file = wiki.find_file('image.png')

        expect(file.mime_type).to eq('image/png')
      end
    end
  end

  describe '#create_page' do
    shared_examples 'create_page tests' do
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

        expect(subject.list_pages.first.version.message).to eq('commit message')
      end

      it 'sets the correct commit email' do
        subject.create_page('test page', 'content')

        expect(user.commit_email).not_to eq(user.email)
        expect(commit.author_email).to eq(user.commit_email)
        expect(commit.committer_email).to eq(user.commit_email)
      end

      it 'runs after_wiki_activity callbacks' do
        expect(subject).to receive(:after_wiki_activity)

        subject.create_page('Test Page', 'This is content')
      end

      it 'cannot create two pages with the same title but different format' do
        subject.create_page('test page', 'content', :markdown)
        subject.create_page('test page', 'content', :rdoc)

        expect(subject.error_message).to match(/Duplicate page:/)
      end

      it 'cannot create two pages with the same title but different capitalization' do
        subject.create_page('test page', 'content')
        subject.create_page('Test page', 'content')

        expect(subject.error_message).to match(/Duplicate page:/)
      end

      it 'cannot create two pages with the same title, different capitalization, and different format' do
        subject.create_page('test page', 'content')
        subject.create_page('Test page', 'content', :rdoc)

        expect(subject.error_message).to match(/Duplicate page:/)
      end

      it 'returns false if a page exists already in the repository', :aggregate_failures do
        subject.create_page('test page', 'content')

        allow(subject).to receive(:file_exists_by_regex?).and_return(false)

        expect(subject.create_page('test page', 'content')).to eq false
        expect(subject.error_message).to match(/Duplicate page:/)
      end

      it 'returns false if it has an invalid format', :aggregate_failures do
        expect(subject.create_page('test page', 'content', :foobar)).to eq false
        expect(subject.error_message).to match(/Invalid format selected/)
      end

      using RSpec::Parameterized::TableSyntax

      where(:new_file, :format, :existing_repo_files, :success) do
        'foo'                       | :markdown   | []                  | true
        'foo'                       | :rdoc       | []                  | true
        'foo'                       | :asciidoc   | []                  | true
        'foo'                       | :org        | []                  | true
        'foo'                       | :textile    | []                  | false
        'foo'                       | :creole     | []                  | false
        'foo'                       | :rest       | []                  | false
        'foo'                       | :mediawiki  | []                  | false
        'foo'                       | :pod        | []                  | false
        'foo'                       | :plaintext  | []                  | false
        'foo'                       | :markdown   | ['foo.md']          | false
        'foo'                       | :markdown   | ['foO.md']          | false
        'foO'                       | :markdown   | ['foo.md']          | false
        'foo'                       | :markdown   | ['foo.mdfoo']       | true
        'foo'                       | :markdown   | ['foo.markdown']    | false
        'foo'                       | :markdown   | ['foo.mkd']         | false
        'foo'                       | :markdown   | ['foo.mkdn']        | false
        'foo'                       | :markdown   | ['foo.mdown']       | false
        'foo'                       | :markdown   | ['foo.adoc']        | false
        'foo'                       | :markdown   | ['foo.asciidoc']    | false
        'foo'                       | :markdown   | ['foo.org']         | false
        'foo'                       | :markdown   | ['foo.rdoc']        | false
        'foo'                       | :markdown   | ['foo.textile']     | false
        'foo'                       | :markdown   | ['foo.creole']      | false
        'foo'                       | :markdown   | ['foo.rest']        | false
        'foo'                       | :markdown   | ['foo.rest.txt']    | false
        'foo'                       | :markdown   | ['foo.rst']         | false
        'foo'                       | :markdown   | ['foo.rst.txt']     | false
        'foo'                       | :markdown   | ['foo.rst.txtfoo']  | true
        'foo'                       | :markdown   | ['foo.mediawiki']   | false
        'foo'                       | :markdown   | ['foo.wiki']        | false
        'foo'                       | :markdown   | ['foo.pod']         | false
        'foo'                       | :markdown   | ['foo.txt']         | false
        'foo'                       | :markdown   | ['foo.Md']          | false
        'foo'                       | :markdown   | ['foo.jpg']         | true
        'foo'                       | :rdoc       | ['foo.md']          | false
        'foo'                       | :rdoc       | ['foO.md']          | false
        'foO'                       | :rdoc       | ['foo.md']          | false
        'foo'                       | :asciidoc   | ['foo.md']          | false
        'foo'                       | :org        | ['foo.md']          | false
        'foo'                       | :markdown   | ['dir/foo.md']      | true
        '/foo'                      | :markdown   | ['foo.md']          | false
        '~foo'                      | :markdown   | []                  | true
        '~~~foo'                    | :markdown   | []                  | true
        './foo'                     | :markdown   | ['foo.md']          | false
        '../foo'                    | :markdown   | ['foo.md']          | false
        '../../foo'                 | :markdown   | ['foo.md']          | false
        '../../foo'                 | :markdown   | ['dir/foo.md']      | true
        'dir/foo'                   | :markdown   | ['foo.md']          | true
        'dir/foo'                   | :markdown   | ['dir/foo.md']      | false
        'dir/foo'                   | :markdown   | ['dir/foo.rdoc']    | false
        '/dir/foo'                  | :markdown   | ['dir/foo.rdoc']    | false
        './dir/foo'                 | :markdown   | ['dir/foo.rdoc']    | false
        '../dir/foo'                | :markdown   | ['dir/foo.rdoc']    | false
        '../dir/../foo'             | :markdown   | ['dir/foo.rdoc']    | true
        '../dir/../foo'             | :markdown   | ['foo.rdoc']        | false
        '../dir/../dir/foo'         | :markdown   | ['dir/foo.rdoc']    | false
        '../dir/../another/foo'     | :markdown   | ['dir/foo.rdoc']    | true
        'another/dir/foo'           | :markdown   | ['dir/foo.md']      | true
        'foo bar'                   | :markdown   | ['foo-bar.md']      | false
        'foo  bar'                  | :markdown   | ['foo-bar.md']      | true
        'föö'.encode('ISO-8859-1')  | :markdown   | ['f��.md']          | false
      end

      with_them do
        specify do
          allow(subject.repository).to receive(:ls_files).and_return(existing_repo_files)

          expect(subject.create_page(new_file, 'content', format)).to eq success
        end
      end
    end

    it_behaves_like 'create_page tests'
  end

  describe '#update_page' do
    shared_examples 'update_page tests' do
      with_them do
        let!(:page) { create(:wiki_page, wiki: subject, title: original_title, format: original_format, content: 'original content') }

        let(:message) { 'updated page' }
        let(:updated_content) { 'updated content' }

        def update_page
          subject.update_page(
            page.page,
            content: updated_content,
            title: updated_title,
            format: updated_format,
            message: message
          )
        end

        specify :aggregate_failures do
          expect(subject).to receive(:after_wiki_activity)
          expect(update_page).to eq true

          page = subject.find_page(expected_title)

          expect(page.raw_content).to eq(updated_content)
          expect(page.path).to eq(expected_path)
          expect(page.version.message).to eq(message)
          expect(user.commit_email).not_to eq(user.email)
          expect(commit.author_email).to eq(user.commit_email)
          expect(commit.committer_email).to eq(user.commit_email)
        end
      end
    end

    shared_context 'common examples' do
      using RSpec::Parameterized::TableSyntax

      where(:original_title, :original_format, :updated_title, :updated_format, :expected_title, :expected_path) do
        'test page'           | :markdown | 'new test page'         | :markdown | 'new test page'         | 'new-test-page.md'
        'test page'           | :markdown | 'test page'             | :markdown | 'test page'             | 'test-page.md'
        'test page'           | :markdown | 'test page'             | :asciidoc | 'test page'             | 'test-page.asciidoc'

        'test page'           | :markdown | 'new dir/new test page' | :markdown | 'new dir/new test page' | 'new-dir/new-test-page.md'
        'test page'           | :markdown | 'new dir/test page'     | :markdown | 'new dir/test page'     | 'new-dir/test-page.md'

        'test dir/test page'  | :markdown | 'new dir/new test page' | :markdown | 'new dir/new test page' | 'new-dir/new-test-page.md'
        'test dir/test page'  | :markdown | 'test dir/test page'    | :markdown | 'test dir/test page'    | 'test-dir/test-page.md'
        'test dir/test page'  | :markdown | 'test dir/test page'    | :asciidoc | 'test dir/test page'    | 'test-dir/test-page.asciidoc'

        'test dir/test page'  | :markdown | 'new test page'         | :markdown | 'new test page'         | 'new-test-page.md'
        'test dir/test page'  | :markdown | 'test page'             | :markdown | 'test page'             | 'test-page.md'

        'test page'           | :markdown | nil                     | :markdown | 'test page'             | 'test-page.md'
        'test.page'           | :markdown | nil                     | :markdown | 'test.page'             | 'test.page.md'

        'testpage'            | :markdown | './testpage'            | :markdown | 'testpage'              | 'testpage.md'
      end
    end

    # There are two bugs in Gollum. THe first one is when the title and the format are updated
    # at the same time https://gitlab.com/gitlab-org/gitlab/-/issues/243519.
    # The second one is when the wiki page is within a dir and the `title` argument
    # we pass to the update method is `nil`. Gollum will remove the dir and move the page.
    #
    # We can include this context into the former once it is fixed
    # or when Gollum is removed since the Gitaly approach already fixes it.
    shared_context 'extended examples' do
      using RSpec::Parameterized::TableSyntax

      where(:original_title, :original_format, :updated_title, :updated_format, :expected_title, :expected_path) do
        'test page'          | :markdown | '~new test page'             | :asciidoc | '~new test page'        | '~new-test-page.asciidoc'
        'test page'          | :markdown | '~~~new test page'           | :asciidoc | '~~~new test page'      | '~~~new-test-page.asciidoc'
        'test page'          | :markdown | 'new test page'              | :asciidoc | 'new test page'         | 'new-test-page.asciidoc'
        'test page'          | :markdown | 'new dir/new test page'      | :asciidoc | 'new dir/new test page' | 'new-dir/new-test-page.asciidoc'
        'test dir/test page' | :markdown | 'new dir/new test page'      | :asciidoc | 'new dir/new test page' | 'new-dir/new-test-page.asciidoc'
        'test dir/test page' | :markdown | 'new test page'              | :asciidoc | 'new test page'         | 'new-test-page.asciidoc'
        'test page'          | :markdown | nil                          | :asciidoc | 'test page'             | 'test-page.asciidoc'
        'test dir/test page' | :markdown | nil                          | :asciidoc | 'test dir/test page'    | 'test-dir/test-page.asciidoc'
        'test dir/test page' | :markdown | nil                          | :markdown | 'test dir/test page'    | 'test-dir/test-page.md'
        'test page'          | :markdown | ''                           | :markdown | 'test page'             | 'test-page.md'
        'test.page'          | :markdown | ''                           | :markdown | 'test.page'             | 'test.page.md'
        'testpage'           | :markdown | '../testpage'                | :markdown | 'testpage'              | 'testpage.md'
        'dir/testpage'       | :markdown | 'dir/../testpage'            | :markdown | 'testpage'              | 'testpage.md'
        'dir/testpage'       | :markdown | './dir/testpage'             | :markdown | 'dir/testpage'          | 'dir/testpage.md'
        'dir/testpage'       | :markdown | '../dir/testpage'            | :markdown | 'dir/testpage'          | 'dir/testpage.md'
        'dir/testpage'       | :markdown | '../dir/../testpage'         | :markdown | 'testpage'              | 'testpage.md'
        'dir/testpage'       | :markdown | '../dir/../dir/testpage'     | :markdown | 'dir/testpage'          | 'dir/testpage.md'
        'dir/testpage'       | :markdown | '../dir/../another/testpage' | :markdown | 'another/testpage'      | 'another/testpage.md'
      end
    end

    it_behaves_like 'update_page tests' do
      include_context 'common examples'
      include_context 'extended examples'
    end

    context 'when format is invalid' do
      let!(:page) { create(:wiki_page, wiki: subject, title: 'test page') }

      it 'returns false and sets error message' do
        expect(subject.update_page(page.page, content: 'new content', format: :foobar)).to eq false
        expect(subject.error_message).to match(/Invalid format selected/)
      end
    end

    context 'when format is not allowed' do
      let!(:page) { create(:wiki_page, wiki: subject, title: 'test page') }

      it 'returns false and sets error message' do
        expect(subject.update_page(page.page, content: 'new content', format: :creole)).to eq false
        expect(subject.error_message).to match(/Invalid format selected/)
      end
    end

    context 'when the repository fails to update' do
      let!(:page) { create(:wiki_page, wiki: subject, title: 'test page') }

      it 'returns false and sets error message', :aggregate_failures do
        expect(subject.repository)
          .to receive(:update_file)
          .and_raise(Gitlab::Git::Index::IndexError.new)

        expect(subject.update_page(page.page, content: 'new content', format: :markdown))
          .to eq(false)
        expect(subject.error_message)
          .to match("Duplicate page: A page with that title already exists")
      end
    end

    context 'when page path does not have a default extension' do
      let!(:page) { create(:wiki_page, wiki: subject, title: 'test page') }

      context 'when format is not different' do
        it 'does not change the default extension' do
          path = 'test-page.markdown'
          page.page.instance_variable_set(:@path, path)

          expect(subject.repository).to receive(:update_file).with(user, path, anything, anything)

          subject.update_page(page.page, content: 'new content', format: :markdown)
        end
      end
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

    it 'runs after_wiki_activity callbacks' do
      page

      expect(subject).to receive(:after_wiki_activity)

      subject.delete_page(page)
    end

    context 'when an error is raised' do
      it 'logs the error and returns false' do
        page = build(:wiki_page, wiki: wiki)
        exception = Gitlab::Git::Index::IndexError.new('foo')

        allow(subject.repository).to receive(:delete_file).and_raise(exception)

        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(exception, action: :deleted, wiki_id: wiki.id)

        expect(subject.delete_page(page)).to be_falsey
      end
    end
  end

  describe '#hook_attrs' do
    it 'returns a hash with values' do
      expect(subject.hook_attrs).to be_a Hash
      expect(subject.hook_attrs.keys).to contain_exactly(:web_url, :git_ssh_url, :git_http_url, :path_with_namespace, :default_branch)
    end
  end

  describe '#default_branch' do
    subject { wiki.default_branch }

    before do
      allow(Gitlab::DefaultBranch).to receive(:value).and_return('main')
    end

    context 'when repository is not created' do
      let(:wiki_container) { wiki_container_without_repo }

      it 'returns the instance default branch' do
        expect(subject).to eq 'main'
      end
    end

    context 'when repository is empty' do
      let(:wiki_container) { wiki_container_without_repo }

      before do
        wiki.repository.create_if_not_exists
      end

      it 'returns the instance default branch' do
        expect(subject).to eq 'main'
      end
    end

    context 'when repository is not empty' do
      it 'returns the repository default branch' do
        wiki.create_page('index', 'test content')

        expect(subject).to eq wiki.repository.root_ref
      end
    end
  end

  describe '#create_wiki_repository' do
    let(:head_path) { Gitlab::GitalyClient::StorageSettings.allow_disk_access { Rails.root.join(TestEnv.repos_path, "#{wiki.disk_path}.git", 'HEAD') } }
    let(:default_branch) { 'foo' }

    before do
      allow(Gitlab::CurrentSettings).to receive(:default_branch_name).and_return(default_branch)
    end

    subject { wiki.create_wiki_repository }

    context 'when repository is not created' do
      let(:wiki_container) { wiki_container_without_repo }

      it 'changes the HEAD reference to the default branch' do
        expect(wiki.empty?).to eq true

        subject

        expect(File.read(head_path).squish).to eq "ref: refs/heads/#{default_branch}"
      end
    end

    context 'when repository is empty' do
      let(:wiki_container) { wiki_container_without_repo }

      it 'creates the repository with the default branch' do
        wiki.repository.create_if_not_exists(default_branch)

        subject

        expect(File.read(head_path).squish).to eq "ref: refs/heads/#{default_branch}"
      end
    end
  end

  describe '#preview_slug' do
    where(:title, :file_extension, :format, :expected_slug) do
      'The Best Thing'       | :md  | :markdown  | 'The-Best-Thing'
      'The Best Thing'       | :txt | :plaintext | 'The-Best-Thing'
      'A Subject/Title Here' | :txt | :plaintext | 'A-Subject/Title-Here'
      'A subject'            | :txt | :plaintext | 'A-subject'
      'A 1/B 2/C 3'          | :txt | :plaintext | 'A-1/B-2/C-3'
      'subject/title'        | :txt | :plaintext | 'subject/title'
      'subject/title.md'     | :txt | :plaintext | 'subject/title.md'
      'foo%2Fbar'            | :txt | :plaintext | 'foo%2Fbar'
      ''                     | :md  | :markdown  | '.md'
      ''                     | :txt | :plaintext | '.txt'
    end

    with_them do
      before do
        subject.repository.create_file(
          user, "#{title}.#{file_extension}", 'content',
          branch_name: subject.default_branch,
          message: "Add #{title}"
        )
      end

      it do
        expect(described_class.preview_slug(title, file_extension)).to eq(expected_slug)
      end

      it 'matches the slug generated by gitaly' do
        skip('Gitaly cannot generate a slug for an empty title') unless title.present?

        gitaly_slug = subject.list_pages.first.slug
        expect(described_class.preview_slug(title, file_extension)).to eq(gitaly_slug)
      end
    end
  end
end
