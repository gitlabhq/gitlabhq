require "spec_helper"

describe WikiPage do
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
        @wiki_page.slug.should == "test-page"
      end

      it "sets the title attribute" do
        @wiki_page.title.should == "test page"
      end

      it "sets the formatted content attribute" do
        @wiki_page.content.should == "test content"
      end

      it "sets the format attribute" do
        @wiki_page.format.should == :markdown
      end

      it "sets the message attribute" do
        @wiki_page.message.should == "test commit"
      end

      it "sets the version attribute" do
        @wiki_page.version.should be_a Commit
      end
    end
  end

  describe "validations" do
    before do
      subject.attributes = {title: 'title', content: 'content'}
    end

    it "validates presence of title" do
      subject.attributes.delete(:title)
      subject.valid?.should be_false
    end

    it "validates presence of content" do
      subject.attributes.delete(:content)
      subject.valid?.should be_false
    end
  end

  before do
    @wiki_attr = {title: "Index", content: "Home Page", format: "markdown"}
  end

  describe "#create" do
    after do
      destroy_page("Index")
    end

    context "with valid attributes" do
      it "saves the wiki page" do
        subject.create(@wiki_attr)
        wiki.find_page("Index").should_not be_nil
      end

      it "returns true" do
        subject.create(@wiki_attr).should == true
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
        @page.update("more content").should be_true
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
      wiki.pages.should be_empty
    end

    it "should return true" do
      @page.delete.should == true
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
      @page.versions.count.should == 4
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
      @page.title.should == "Import existing repositories into GitLab"
    end
  end

  private

  def remove_temp_repo(path)
    FileUtils.rm_rf path
  end

  def commit_details
    commit = {name: user.name, email: user.email, message: "test commit"}
  end

  def create_page(name, content)
    wiki.wiki.write_page(name, :markdown, content, commit_details)
  end

  def destroy_page(title)
    page = wiki.wiki.paged(title)
    wiki.wiki.delete_page(page, commit_details)
  end
end
