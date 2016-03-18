require "spec_helper"

describe WikiPage, models: true do
  let(:project) { create(:empty_project) }
  let(:user) { project.owner }
  let(:wiki) { ProjectWiki.new(project, user) }

  subject { WikiPage.new(wiki) }

  describe "#initialize" do
    context "when initialized with an existing gollum page" do
      before do
        create_page("test page", "test content")
        @page = wiki.wiki.paged("test page")
        @wiki_page = WikiPage.new(wiki, @page, true)
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
        expect(@wiki_page.version).to be_a Gollum::Git::Commit
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
        @page.update("new content")
        @page = wiki.find_page(title)
      end

      it "returns true" do
        expect(@page.update("more content")).to be_truthy
      end
    end
  end

  describe "#update" do
    before do
      create_page("Update", "content")
      @page = wiki.find_page("Update")
    end

    after do
      destroy_page("Update")
    end

    context "with valid attributes" do
      it "updates the content of the page" do
        @page.update("new content")
        @page = wiki.find_page("Update")
      end

      it "returns true" do
        expect(@page.update("more content")).to be_truthy
      end
    end
  end

  describe "#destroy" do
    before do
      create_page("Delete Page", "content")
      @page = wiki.find_page("Delete Page")
    end

    it "should delete the page" do
      @page.delete
      expect(wiki.pages).to be_empty
    end

    it "should return true" do
      expect(@page.delete).to eq(true)
    end
  end

  describe "#versions" do
    before do
      create_page("Update", "content")
      @page = wiki.find_page("Update")
    end

    after do
      destroy_page("Update")
    end

    it "returns an array of all commits for the page" do
      3.times { |i| @page.update("content #{i}") }
      expect(@page.versions.count).to eq(4)
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

    it "should be replace a hyphen to a space" do
      @page.title = "Import-existing-repositories-into-GitLab"
      expect(@page.title).to eq("Import existing repositories into GitLab")
    end
  end

  describe '#historical?' do
    before do
      create_page('Update', 'content')
      @page = wiki.find_page('Update')
      3.times { |i| @page.update("content #{i}") }
    end

    after do
      destroy_page('Update')
    end

    it 'returns true when requesting an old version' do
      old_version = @page.versions.last.to_s
      old_page = wiki.find_page('Update', old_version)

      expect(old_page.historical?).to eq true
    end

    it 'returns false when requesting latest version' do
      latest_version = @page.versions.first.to_s
      latest_page = wiki.find_page('Update', latest_version)

      expect(latest_page.historical?).to eq false
    end

    it 'returns false when version is nil' do
      latest_page = wiki.find_page('Update', nil)

      expect(latest_page.historical?).to eq false
    end
  end

  private

  def remove_temp_repo(path)
    FileUtils.rm_rf path
  end

  def commit_details
    { name: user.name, email: user.email, message: "test commit" }
  end

  def create_page(name, content)
    wiki.wiki.write_page(name, :markdown, content, commit_details)
  end

  def destroy_page(title)
    page = wiki.wiki.paged(title)
    wiki.wiki.delete_page(page, commit_details)
  end
end
