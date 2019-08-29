# frozen_string_literal: true

require 'spec_helper'

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

        expect(link['href']).to eq 'http://issue-tracker.example.com/issues/12'
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

        expect(link['href']).to eq 'http://issue-tracker.example.com/issues/12'
      end

      it 'allows to use long external reference syntax for Redmine' do
        markdown = 'API_32-12'

        result = described_class.call(markdown, project: project)[:output]
        link = result.css('a').first

        expect(link['href']).to eq 'http://issue-tracker.example.com/issues/12'
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

  describe 'markdown link or image urls having spaces' do
    let(:project) { create(:project, :public) }

    it 'rewrites links with spaces in url' do
      markdown = "[Link to Page](page slug)"
      output = described_class.to_html(markdown, project: project)

      expect(output).to include("href=\"page%20slug\"")
    end

    it 'rewrites images with spaces in url' do
      markdown = "![My Image](test image.png)"
      output = described_class.to_html(markdown, project: project)

      expect(output).to include("src=\"test%20image.png\"")
    end

    it 'sanitizes the fixed link' do
      markdown_xss = "[xss](javascript: alert%28document.domain%29)"
      output = described_class.to_html(markdown_xss, project: project)

      expect(output).not_to include("javascript")

      markdown_xss = "<invalidtag>\n[xss](javascript:alert%28document.domain%29)"
      output = described_class.to_html(markdown_xss, project: project)

      expect(output).not_to include("javascript")
    end
  end

  describe 'emoji in references' do
    set(:project) { create(:project, :public) }
    let(:emoji) { '💯' }

    it 'renders a label reference with emoji inside' do
      create(:label, project: project, name: emoji)

      output = described_class.to_html("#{Label.reference_prefix}\"#{emoji}\"", project: project)

      expect(output).to include(emoji)
      expect(output).to include(Gitlab::Routing.url_helpers.project_issues_path(project, label_name: emoji))
    end

    it 'renders a milestone reference with emoji inside' do
      milestone = create(:milestone, project: project, title: emoji)

      output = described_class.to_html("#{Milestone.reference_prefix}\"#{emoji}\"", project: project)

      expect(output).to include(emoji)
      expect(output).to include(Gitlab::Routing.url_helpers.milestone_path(milestone))
    end
  end
end
