# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GoogleCodeImport::ProjectCreator do
  let(:user) { create(:user) }
  let(:repo) do
    Gitlab::GoogleCodeImport::Repository.new(
      "name" => 'vim',
      "summary" => 'VI Improved',
      "repositoryUrls" => ["https://vim.googlecode.com/git/"]
    )
  end
  let(:namespace) { create(:group) }

  before do
    namespace.add_owner(user)
  end

  it 'creates project' do
    expect_next_instance_of(Project) do |project|
      expect(project).to receive(:add_import_job)
    end

    project_creator = described_class.new(repo, namespace, user)
    project = project_creator.execute

    expect(project.import_url).to eq("https://vim.googlecode.com/git/")
    expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
  end
end
