require 'spec_helper'

describe Gitlab::GitoriousImport::ProjectCreator, lib: true do
  let(:user) { create(:user) }
  let(:repo) { Gitlab::GitoriousImport::Repository.new('foo/bar-baz-qux') }
  let(:namespace){ create(:group, owner: user) }

  before do
    namespace.add_owner(user)
  end

  it 'creates project' do
    allow_any_instance_of(Project).to receive(:add_import_job)

    project_creator = Gitlab::GitoriousImport::ProjectCreator.new(repo, namespace, user)
    project = project_creator.execute

    expect(project.name).to eq("Bar Baz Qux")
    expect(project.path).to eq("bar-baz-qux")
    expect(project.namespace).to eq(namespace)
    expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
    expect(project.import_type).to eq("gitorious")
    expect(project.import_source).to eq("foo/bar-baz-qux")
    expect(project.import_url).to eq("https://gitorious.org/foo/bar-baz-qux.git")
  end
end
