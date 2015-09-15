require 'spec_helper'

describe Ci::CreateProjectService do
  let(:service) { Ci::CreateProjectService.new }
  let(:current_user) { double.as_null_object }
  let(:project_dump) { YAML.load File.read(Rails.root.join('spec/support/gitlab_stubs/raw_project.yml')) }

  describe :execute do
    context 'valid params' do
      let(:project) { service.execute(current_user, project_dump, 'http://localhost/projects/:project_id') }

      it { expect(project).to be_kind_of(Project) }
      it { expect(project).to be_persisted }
    end

    context 'without project dump' do
      it 'should raise exception' do
        expect { service.execute(current_user, '', '') }.to raise_error
      end
    end

    context "forking" do
      it "uses project as a template for settings and jobs" do
        origin_project = FactoryGirl.create(:ci_project)
        origin_project.shared_runners_enabled = true
        origin_project.public = true
        origin_project.allow_git_fetch = true
        origin_project.save!

        project = service.execute(current_user, project_dump, 'http://localhost/projects/:project_id', origin_project)

        expect(project.shared_runners_enabled).to be_truthy
        expect(project.public).to be_truthy
        expect(project.allow_git_fetch).to be_truthy
      end
    end
  end
end
