require 'spec_helper'

describe "Projects", elastic: true do
  before do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(true)
    Project.__elasticsearch__.create_index!
  end

  after do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(false)
    Project.__elasticsearch__.delete_index!
  end

  it "searches projects" do
    @project = create :empty_project, name: 'test'
    @project1 = create :empty_project, path: 'test1'
    @project2 = create :empty_project
    @project3 = create :empty_project, path: 'someone_elses_project'
    @project_ids = [@project.id, @project1.id, @project2.id]
    
    Project.__elasticsearch__.refresh_index!

    expect(Project.elastic_search('test', options: { pids: @project_ids }).total_count).to eq(1)
    expect(Project.elastic_search('test1', options: { pids: @project_ids }).total_count).to eq(1)
    expect(Project.elastic_search('someone_elses_project', options: { pids: @project_ids }).total_count).to eq(0)
  end
end
