require "spec_helper"

describe WikiToGollumMigrator do

  def create_wiki_for(project)
    3.times { @pages[project.id] << create_page(project) }
  end

  def create_revisions_for(project)
    @pages[project.id].each do |page|
      create_revision(page)
    end
  end

  def create_page(project)
    page = project.wikis.new(title: "Page #{rand(1000)}", content: "Content")
    page.user = project.owner
    page.slug = page.title.parameterize
    page.save!
    page
  end

  def create_revision(page)
    revision = page.dup
    revision.content = "Updated Content"
    revision.save!
  end

  def create_temp_repo(path)
    FileUtils.mkdir_p path
    command = "git init --quiet --bare #{path};"
    system(command)
  end

  before do
    @repo_path = "#{Rails.root}/tmp/test-git-base-path"
    @projects = []
    @pages = Hash.new {|h,k| h[k] = Array.new }

    @projects << create(:project)
    @projects << create(:project)

    @projects.each do |project|
      create_wiki_for project
      create_revisions_for project
    end

    @project_without_wiki = create(:project)
  end

  context "Before the migration" do
    it "has two projects with valid wikis" do
      @projects.each do |project|
        pages = project.wikis.group(:slug).all
        pages.count.should == 3
      end
    end

    it "has two revision for each page" do
      @projects.each do |project|
        @pages[project.id].each do |page|
          revisions = project.wikis.where(slug: page.slug)
          revisions.count.should == 2
        end
      end
    end
  end

  describe "#initialize" do
    it "finds all projects that have existing wiki pages" do
      Project.count.should == 3
      subject.projects.count.should == 2
    end
  end

  context "#migrate!" do
    before do
      Gitlab::Shell.any_instance.stub(:add_repository) do |path|
        create_temp_repo("#{@repo_path}/#{path}.git")
      end

      subject.stub(:log).as_null_object

      subject.migrate!
    end

    it "creates a new Gollum Wiki for each project" do
      @projects.each do |project|
        wiki_path = project.path_with_namespace + ".wiki.git"
        full_path = @repo_path + "/" + wiki_path
        File.exist?(full_path).should be_true
        File.directory?(full_path).should be_true
      end
    end

    it "creates a gollum page for each unique Wiki page" do
      @projects.each do |project|
        wiki = GollumWiki.new(project, nil)
        wiki.pages.count.should == 3
      end
    end

    it "creates a new revision for each old revision of the page" do
      @projects.each do |project|
        wiki = GollumWiki.new(project, nil)
        wiki.pages.each do |page|
          page.versions.count.should == 2
        end
      end
    end
  end


end
