require 'rails_helper'

describe Banzai::Pipeline::GfmPipeline do
  describe 'integration between parsing regular and external issue references' do
    let(:project) { create(:redmine_project, :public) }

    context 'when internal issue tracker is enabled' do
      context 'when shorthand pattern #ISSUE_ID is used' do
        it 'links an internal issue  if it exists' do
          issue = create(:issue, project: project)
          markdown = issue.to_reference(project, full: true)

          result = described_class.call(markdown, project: project)[:output]
          link = result.css('a').first

          expect(link['href']).to eq(
            Gitlab::Routing.url_helpers.project_issue_path(project, issue)
          )
        end

        it 'does not link any issue if it does not exist on GitLab' do
          markdown = '#12'

          result = described_class.call(markdown, project: project)[:output]
          expect(result.css('a')).to be_empty
        end
      end

      it 'allows to use long external reference syntax for Redmine' do
        markdown = 'API_32-12'

        result = described_class.call(markdown, project: project)[:output]
        link = result.css('a').first

        expect(link['href']).to eq 'http://redmine/projects/project_name_in_redmine/issues/12'
      end

      it 'parses cross-project references to regular issues' do
        other_project = create(:project, :public)
        issue = create(:issue, project: other_project)
        markdown = issue.to_reference(project, full: true)

        result = described_class.call(markdown, project: project)[:output]
        link = result.css('a').first

        expect(link['href']).to eq(
          Gitlab::Routing.url_helpers.project_issue_path(other_project, issue)
        )
      end
    end

    context 'when internal issue tracker is disabled' do
      before do
        project.issues_enabled = false
        project.save!
      end

      it 'allows to use shorthand external reference syntax for Redmine' do
        markdown = '#12'

        result = described_class.call(markdown, project: project)[:output]
        link = result.css('a').first

        expect(link['href']).to eq 'http://redmine/projects/project_name_in_redmine/issues/12'
      end

      it 'allows to use long external reference syntax for Redmine' do
        markdown = 'API_32-12'

        result = described_class.call(markdown, project: project)[:output]
        link = result.css('a').first

        expect(link['href']).to eq 'http://redmine/projects/project_name_in_redmine/issues/12'
      end

      it 'parses cross-project references to regular issues' do
        other_project = create(:project, :public)
        issue = create(:issue, project: other_project)
        markdown = issue.to_reference(project, full: true)

        result = described_class.call(markdown, project: project)[:output]
        link = result.css('a').first

        expect(link['href']).to eq(
          Gitlab::Routing.url_helpers.project_issue_path(other_project, issue)
        )
      end
    end
  end
end
