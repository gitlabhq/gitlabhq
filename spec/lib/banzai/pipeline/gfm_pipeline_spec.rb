require 'rails_helper'

describe Banzai::Pipeline::GfmPipeline do
  describe 'integration between parsing regular and external issue references' do
    let(:project) { create(:redmine_project, :public) }

    it 'allows to use shorthand external reference syntax for Redmine' do
      markdown = '#12'

      result = described_class.call(markdown, project: project)[:output]
      link = result.css('a').first

      expect(link['href']).to eq 'http://redmine/projects/project_name_in_redmine/issues/12'
    end

    it 'parses cross-project references to regular issues' do
      other_project = create(:empty_project, :public)
      issue = create(:issue, project: other_project)
      markdown = issue.to_reference(project, full: true)

      result = described_class.call(markdown, project: project)[:output]
      link = result.css('a').first

      expect(link['href']).to eq(
        Gitlab::Routing.url_helpers.namespace_project_issue_path(
          other_project.namespace,
          other_project,
          issue
        )
      )
    end
  end
end
