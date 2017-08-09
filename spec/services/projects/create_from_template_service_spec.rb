require 'spec_helper'

describe Projects::CreateFromTemplateService do
  let(:user) { create(:user) }
  let(:project_params) do
    {
      path: user.to_param,
      template_name: 'rails'
    }
  end

  subject { described_class.new(user, project_params) }

  it 'calls the importer service' do
    expect_any_instance_of(Projects::GitlabProjectsImportService).to receive(:execute)

    subject.execute
  end

  it 'returns the project thats created' do
    project = subject.execute

    expect(project).to be_saved
    expect(project.scheduled?).to be(true)
  end
end
