require 'spec_helper'

describe Gitlab::ProjectMover do
  let(:base_path) { Rails.root.join('tmp', 'rspec-sandbox') }

  before do
    FileUtils.rm_rf base_path if File.exists? base_path

    Gitlab.config.gitolite.stub(repos_path: base_path)

    @project = create(:project)
  end

  after do
    FileUtils.rm_rf base_path
  end

  it "should move project to subdir" do
    mk_dir base_path, '', @project.path
    mover = Gitlab::ProjectMover.new(@project, '', 'opensource')

    mover.execute.should be_true
    moved?('opensource', @project.path).should be_true
  end

  it "should move project from one subdir to another" do
    mk_dir base_path, 'vsizov', @project.path
    mover = Gitlab::ProjectMover.new(@project, 'vsizov', 'randx')

    mover.execute.should be_true
    moved?('randx', @project.path).should be_true
  end

  it "should move project from subdir to base" do
    mk_dir base_path, 'vsizov', @project.path
    mover = Gitlab::ProjectMover.new(@project, 'vsizov', '')

    mover.execute.should be_true
    moved?('', @project.path).should be_true
  end

  it "should raise if destination exists" do
    mk_dir base_path, '', @project.path
    mk_dir base_path, 'vsizov', @project.path
    mover = Gitlab::ProjectMover.new(@project, 'vsizov', '')

    expect { mover.execute }.to raise_error(Gitlab::ProjectMover::ProjectMoveError)
  end

  it "should raise if move failed" do
    mk_dir base_path
    mover = Gitlab::ProjectMover.new(@project, 'vsizov', '')

    expect { mover.execute }.to raise_error(Gitlab::ProjectMover::ProjectMoveError)
  end


  def mk_dir base_path, namespace = '', project_path = ''
    FileUtils.mkdir_p File.join(base_path, namespace, project_path + ".git")
  end

  def moved? namespace, path
    File.exists?(File.join(base_path, namespace, path + '.git'))
  end
end
