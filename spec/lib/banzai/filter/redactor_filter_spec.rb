require 'spec_helper'

describe Banzai::Filter::RedactorFilter, lib: true do
  include ActionView::Helpers::UrlHelper
  include FilterSpecHelper

  it 'ignores non-GFM links' do
    html = %(See <a href="https://google.com/">Google</a>)
    doc = filter(html, current_user: double)

    expect(doc.css('a').length).to eq 1
  end

  def reference_link(data)
    link_to('text', '', class: 'gfm', data: data)
  end

  context 'with data-project' do
    it 'removes unpermitted Project references' do
      user = create(:user)
      project = create(:empty_project)

      link = reference_link(project: project.id, reference_filter: 'ReferenceFilter')
      doc = filter(link, current_user: user)

      expect(doc.css('a').length).to eq 0
    end

    it 'allows permitted Project references' do
      user = create(:user)
      project = create(:empty_project)
      project.team << [user, :master]

      link = reference_link(project: project.id, reference_filter: 'ReferenceFilter')
      doc = filter(link, current_user: user)

      expect(doc.css('a').length).to eq 1
    end

    it 'handles invalid Project references' do
      link = reference_link(project: 12345, reference_filter: 'ReferenceFilter')

      expect { filter(link) }.not_to raise_error
    end
  end

  context 'with data-issue' do
    context 'for confidential issues' do
      it 'removes references for non project members' do
        non_member = create(:user)
        project = create(:empty_project, :public)
        issue = create(:issue, :confidential, project: project)

        link = reference_link(project: project.id, issue: issue.id, reference_filter: 'IssueReferenceFilter')
        doc = filter(link, current_user: non_member)

        expect(doc.css('a').length).to eq 0
      end

      it 'allows references for author' do
        author = create(:user)
        project = create(:empty_project, :public)
        issue = create(:issue, :confidential, project: project, author: author)

        link = reference_link(project: project.id, issue: issue.id, reference_filter: 'IssueReferenceFilter')
        doc = filter(link, current_user: author)

        expect(doc.css('a').length).to eq 1
      end

      it 'allows references for assignee' do
        assignee = create(:user)
        project = create(:empty_project, :public)
        issue = create(:issue, :confidential, project: project, assignee: assignee)

        link = reference_link(project: project.id, issue: issue.id, reference_filter: 'IssueReferenceFilter')
        doc = filter(link, current_user: assignee)

        expect(doc.css('a').length).to eq 1
      end

      it 'allows references for project members' do
        member = create(:user)
        project = create(:empty_project, :public)
        project.team << [member, :developer]
        issue = create(:issue, :confidential, project: project)

        link = reference_link(project: project.id, issue: issue.id, reference_filter: 'IssueReferenceFilter')
        doc = filter(link, current_user: member)

        expect(doc.css('a').length).to eq 1
      end

      it 'allows references for admin' do
        admin = create(:admin)
        project = create(:empty_project, :public)
        issue = create(:issue, :confidential, project: project)

        link = reference_link(project: project.id, issue: issue.id, reference_filter: 'IssueReferenceFilter')
        doc = filter(link, current_user: admin)

        expect(doc.css('a').length).to eq 1
      end
    end

    it 'allows references for non confidential issues' do
      user = create(:user)
      project = create(:empty_project, :public)
      issue = create(:issue, project: project)

      link = reference_link(project: project.id, issue: issue.id, reference_filter: 'IssueReferenceFilter')
      doc = filter(link, current_user: user)

      expect(doc.css('a').length).to eq 1
    end
  end

  context "for user references" do
    context 'with data-group' do
      it 'removes unpermitted Group references' do
        user = create(:user)
        group = create(:group)

        link = reference_link(group: group.id, reference_filter: 'UserReferenceFilter')
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 0
      end

      it 'allows permitted Group references' do
        user = create(:user)
        group = create(:group)
        group.add_developer(user)

        link = reference_link(group: group.id, reference_filter: 'UserReferenceFilter')
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 1
      end

      it 'handles invalid Group references' do
        link = reference_link(group: 12345, reference_filter: 'UserReferenceFilter')

        expect { filter(link) }.not_to raise_error
      end
    end

    context 'with data-user' do
      it 'allows any User reference' do
        user = create(:user)

        link = reference_link(user: user.id, reference_filter: 'UserReferenceFilter')
        doc = filter(link)

        expect(doc.css('a').length).to eq 1
      end
    end
  end
end
