require "spec_helper"

describe ProjectWiki do
  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:user) { project.owner }
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:project_wiki) { described_class.new(project, user) }
  let(:raw_repository) { Gitlab::Git::Repository.new(project.repository_storage, subject.disk_path + '.git', 'foo') }

  subject { project_wiki }

  it { is_expected.to delegate_method(:empty?).to :pages }
  it { is_expected.to delegate_method(:repository_storage_path).to :project }
  it { is_expected.to delegate_method(:hashed_storage?).to :project }

  describe "#full_path" do
    it "returns the project path with namespace with the .wiki extension" do
      expect(subject.full_path).to eq(project.full_path + '.wiki')
    end

    it 'returns the same value as #full_path' do
      expect(subject.full_path).to eq(subject.full_path)
    end
  end

  describe '#web_url' do
    it 'returns the full web URL to the wiki' do
      expect(subject.web_url).to eq("#{Gitlab.config.gitlab.url}/#{project.full_path}/wikis/home")
    end
  end

  describe "#url_to_repo" do
    it "returns the correct ssh url to the repo" do
      expect(subject.url_to_repo).to eq(gitlab_shell.url_to_repo(subject.full_path))
    end
  end

  describe "#ssh_url_to_repo" do
    it "equals #url_to_repo" do
      expect(subject.ssh_url_to_repo).to eq(subject.url_to_repo)
    end
  end

  describe "#http_url_to_repo" do
    let(:project) { create :project }

    it 'returns the full http url to the repo' do
      expected_url = "#{Gitlab.config.gitlab.url}/#{subject.full_path}.git"

      expect(project_wiki.http_url_to_repo).to eq(expected_url)
      expect(project_wiki.http_url_to_repo).not_to include('@')
    end
  end

  describe "#wiki_base_path" do
    it "returns the wiki base path" do
      wiki_base_path = "#{Gitlab.config.gitlab.relative_url_root}/#{project.full_path}/wikis"

      expect(subject.wiki_base_path).to eq(wiki_base_path)
    end
  end

  describe "#wiki" do
    it "contains a Gitlab::Git::Wiki instance" do
      expect(subject.wiki).to be_a Gitlab::Git::Wiki
    end

    it "creates a new wiki repo if one does not yet exist" do
      expect(project_wiki.create_page("index", "test content")).to be_truthy
    end

    it "raises CouldNotCreateWikiError if it can't create the wiki repository" do
      # Create a fresh project which will not have a wiki
      project_wiki = described_class.new(create(:project), user)
      gitlab_shell = double(:gitlab_shell)
      allow(gitlab_shell).to receive(:create_repository)
      allow(project_wiki).to receive(:gitlab_shell).and_return(gitlab_shell)

      expect { project_wiki.send(:wiki) }.to raise_exception(ProjectWiki::CouldNotCreateWikiError)
    end
  end

  describe "#empty?" do
    context "when the wiki repository is empty" do
      describe '#empty?' do
        subject { super().empty? }
        it { is_expected.to be_truthy }
      end
    end

    context "when the wiki has pages" do
      before do
        project_wiki.create_page("index", "This is an awesome new Gollum Wiki")
      end

      describe '#empty?' do
        subject { super().empty? }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe "#pages" do
    before do
      create_page("index", "This is an awesome new Gollum Wiki")
      @pages = subject.pages
    end

    after do
      destroy_page(@pages.first.page)
    end

    it "returns an array of WikiPage instances" do
      expect(@pages.first).to be_a WikiPage
    end

    it "returns the correct number of pages" do
      expect(@pages.count).to eq(1)
    end
  end

  describe "#find_page" do
    shared_examples 'finding a wiki page' do
      before do
        create_page("index page", "This is an awesome Gollum Wiki")
      end

      after do
        subject.pages.each { |page| destroy_page(page.page) }
      end

      it "returns the latest version of the page if it exists" do
        page = subject.find_page("index page")
        expect(page.title).to eq("index page")
      end

      it "returns nil if the page does not exist" do
        expect(subject.find_page("non-existant")).to eq(nil)
      end

      it "can find a page by slug" do
        page = subject.find_page("index-page")
        expect(page.title).to eq("index page")
      end

      it "returns a WikiPage instance" do
        page = subject.find_page("index page")
        expect(page).to be_a WikiPage
      end

      context 'pages with multibyte-character title' do
        before do
          create_page("autre pagé", "C'est un génial Gollum Wiki")
        end

        it "can find a page by slug" do
          page = subject.find_page("autre pagé")
          expect(page.title).to eq("autre pagé")
        end
      end
    end

    context 'when Gitaly wiki_find_page is enabled' do
      it_behaves_like 'finding a wiki page'
    end

    context 'when Gitaly wiki_find_page is disabled', :skip_gitaly_mock do
      it_behaves_like 'finding a wiki page'
    end
  end

  describe '#find_sidebar' do
    before do
      create_page(described_class::SIDEBAR, 'This is an awesome Sidebar')
    end

    after do
      subject.pages.each { |page| destroy_page(page.page) }
    end

    it 'finds the page defined as _sidebar' do
      page = subject.find_page('_sidebar')

      expect(page.content).to eq('This is an awesome Sidebar')
    end
  end

  describe '#find_file' do
    shared_examples 'finding a wiki file' do
      before do
        file = File.open(Rails.root.join('spec', 'fixtures', 'dk.png'))
        subject.wiki # Make sure the wiki repo exists

        BareRepoOperations.new(subject.repository.path_to_repo).commit_file(file, 'image.png')
      end

      it 'returns the latest version of the file if it exists' do
        file = subject.find_file('image.png')
        expect(file.mime_type).to eq('image/png')
      end

      it 'returns nil if the page does not exist' do
        expect(subject.find_file('non-existant')).to eq(nil)
      end

      it 'returns a Gitlab::Git::WikiFile instance' do
        file = subject.find_file('image.png')
        expect(file).to be_a Gitlab::Git::WikiFile
      end
    end

    context 'when Gitaly wiki_find_file is enabled' do
      it_behaves_like 'finding a wiki file'
    end

    context 'when Gitaly wiki_find_file is disabled', :skip_gitaly_mock do
      it_behaves_like 'finding a wiki file'
    end
  end

  describe "#create_page" do
    shared_examples 'creating a wiki page' do
      after do
        destroy_page(subject.pages.first.page)
      end

      it "creates a new wiki page" do
        expect(subject.create_page("test page", "this is content")).not_to eq(false)
        expect(subject.pages.count).to eq(1)
      end

      it "returns false when a duplicate page exists" do
        subject.create_page("test page", "content")
        expect(subject.create_page("test page", "content")).to eq(false)
      end

      it "stores an error message when a duplicate page exists" do
        2.times { subject.create_page("test page", "content") }
        expect(subject.error_message).to match(/Duplicate page:/)
      end

      it "sets the correct commit message" do
        subject.create_page("test page", "some content", :markdown, "commit message")
        expect(subject.pages.first.page.version.message).to eq("commit message")
      end

      it 'updates project activity' do
        subject.create_page('Test Page', 'This is content')

        project.reload

        expect(project.last_activity_at).to be_within(1.minute).of(Time.now)
        expect(project.last_repository_updated_at).to be_within(1.minute).of(Time.now)
      end
    end

    context 'when Gitaly wiki_write_page is enabled' do
      it_behaves_like 'creating a wiki page'
    end

    context 'when Gitaly wiki_write_page is disabled', :skip_gitaly_mock do
      it_behaves_like 'creating a wiki page'
    end
  end

  describe "#update_page" do
    before do
      create_page("update-page", "some content")
      @gitlab_git_wiki_page = subject.wiki.page(title: "update-page")
      subject.update_page(
        @gitlab_git_wiki_page,
        content: "some other content",
        format: :markdown,
        message: "updated page"
      )
      @page = subject.pages.first.page
    end

    after do
      destroy_page(@page)
    end

    it "updates the content of the page" do
      expect(@page.raw_data).to eq("some other content")
    end

    it "sets the correct commit message" do
      expect(@page.version.message).to eq("updated page")
    end

    it 'updates project activity' do
      subject.update_page(
        @gitlab_git_wiki_page,
        content: 'Yet more content',
        format: :markdown,
        message: 'Updated page again'
      )

      project.reload

      expect(project.last_activity_at).to be_within(1.minute).of(Time.now)
      expect(project.last_repository_updated_at).to be_within(1.minute).of(Time.now)
    end
  end

  describe "#delete_page" do
    shared_examples 'deleting a wiki page' do
      before do
        create_page("index", "some content")
        @page = subject.wiki.page(title: "index")
      end

      it "deletes the page" do
        subject.delete_page(@page)
        expect(subject.pages.count).to eq(0)
      end

      it 'updates project activity' do
        subject.delete_page(@page)

        project.reload

        expect(project.last_activity_at).to be_within(1.minute).of(Time.now)
        expect(project.last_repository_updated_at).to be_within(1.minute).of(Time.now)
      end
    end

    context 'when Gitaly wiki_delete_page is enabled' do
      it_behaves_like 'deleting a wiki page'
    end

    context 'when Gitaly wiki_delete_page is disabled', :skip_gitaly_mock do
      it_behaves_like 'deleting a wiki page'
    end
  end

  describe '#create_repo!' do
    it 'creates a repository' do
      expect(raw_repository.exists?).to eq(false)
      expect(subject.repository).to receive(:after_create)

      subject.send(:create_repo!, raw_repository)

      expect(raw_repository.exists?).to eq(true)
    end
  end

  describe '#ensure_repository' do
    it 'creates the repository if it not exist' do
      expect(raw_repository.exists?).to eq(false)

      expect(subject).to receive(:create_repo!).and_call_original
      subject.ensure_repository

      expect(raw_repository.exists?).to eq(true)
    end

    it 'does not create the repository if it exists' do
      subject.wiki
      expect(raw_repository.exists?).to eq(true)

      expect(subject).not_to receive(:create_repo!)

      subject.ensure_repository
    end
  end

  describe '#hook_attrs' do
    it 'returns a hash with values' do
      expect(subject.hook_attrs).to be_a Hash
      expect(subject.hook_attrs.keys).to contain_exactly(:web_url, :git_ssh_url, :git_http_url, :path_with_namespace, :default_branch)
    end
  end

  private

  def create_temp_repo(path)
    FileUtils.mkdir_p path
    system(*%W(#{Gitlab.config.git.bin_path} init --quiet --bare -- #{path}))
  end

  def remove_temp_repo(path)
    FileUtils.rm_rf path
  end

  def commit_details
    Gitlab::Git::Wiki::CommitDetails.new(user.name, user.email, "test commit")
  end

  def create_page(name, content)
    subject.wiki.write_page(name, :markdown, content, commit_details)
  end

  def destroy_page(page)
    subject.delete_page(page, "test commit")
  end
end
