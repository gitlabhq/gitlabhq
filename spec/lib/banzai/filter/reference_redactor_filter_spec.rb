# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::ReferenceRedactorFilter do
  include ActionView::Helpers::UrlHelper
  include FilterSpecHelper

  it 'ignores non-GFM links' do
    html = %(See <a href="https://google.com/">Google</a>)
    doc = filter(html, current_user: build(:user))

    expect(doc.css('a').length).to eq 1
  end

  def reference_link(data)
    link_to('text', '', class: 'gfm', data: data)
  end

  it 'skips when the skip_redaction flag is set' do
    user = create(:user)
    project = create(:project)

    link = reference_link(project: project.id, reference_type: 'test')
    doc = filter(link, current_user: user, skip_redaction: true)

    expect(doc.css('a').length).to eq 1
  end

  context 'with data-project' do
    let(:parser_class) do
      Class.new(Banzai::ReferenceParser::BaseParser) do
        self.reference_type = :test
      end
    end

    before do
      allow(Banzai::ReferenceParser).to receive(:[])
        .with('test')
        .and_return(parser_class)
    end

    context 'valid projects' do
      before do
        allow_next_instance_of(Banzai::ReferenceParser::BaseParser) do |instance|
          allow(instance).to receive(:can_read_reference?).and_return(true)
        end
      end

      it 'allows permitted Project references' do
        user = create(:user)
        project = create(:project)
        project.add_maintainer(user)

        link = reference_link(project: project.id, reference_type: 'test')
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 1
      end
    end

    context 'invalid projects' do
      before do
        allow_next_instance_of(Banzai::ReferenceParser::BaseParser) do |instance|
          allow(instance).to receive(:can_read_reference?).and_return(false)
        end
      end

      it 'removes unpermitted references' do
        user = create(:user)
        project = create(:project)

        link = reference_link(project: project.id, reference_type: 'test')
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 0
      end

      it 'handles invalid references' do
        link = reference_link(project: 12345, reference_type: 'test')

        expect { filter(link) }.not_to raise_error
      end
    end
  end

  context 'with data-issue' do
    context 'for confidential issues' do
      it 'removes references for non project members' do
        non_member = create(:user)
        project = create(:project, :public)
        issue = create(:issue, :confidential, project: project)

        link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')
        doc = filter(link, current_user: non_member)

        expect(doc.css('a').length).to eq 0
      end

      it 'removes references for project members with guest role' do
        member = create(:user)
        project = create(:project, :public)
        project.add_guest(member)
        issue = create(:issue, :confidential, project: project)

        link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')
        doc = filter(link, current_user: member)

        expect(doc.css('a').length).to eq 0
      end

      it 'allows references for author' do
        author = create(:user)
        project = create(:project, :public)
        issue = create(:issue, :confidential, project: project, author: author)

        link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')
        doc = filter(link, current_user: author)

        expect(doc.css('a').length).to eq 1
      end

      it 'allows references for assignee' do
        assignee = create(:user)
        project = create(:project, :public)
        issue = create(:issue, :confidential, project: project, assignees: [assignee])

        link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')
        doc = filter(link, current_user: assignee)

        expect(doc.css('a').length).to eq 1
      end

      it 'allows references for project members' do
        member = create(:user)
        project = create(:project, :public)
        project.add_developer(member)
        issue = create(:issue, :confidential, project: project)

        link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')
        doc = filter(link, current_user: member)

        expect(doc.css('a').length).to eq 1
      end

      it 'allows references for admin' do
        admin = create(:admin)
        project = create(:project, :public)
        issue = create(:issue, :confidential, project: project)

        link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')
        doc = filter(link, current_user: admin)

        expect(doc.css('a').length).to eq 1
      end
    end

    it 'allows references for non confidential issues' do
      user = create(:user)
      project = create(:project, :public)
      issue = create(:issue, project: project)

      link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')
      doc = filter(link, current_user: user)

      expect(doc.css('a').length).to eq 1
    end
  end

  context "for user references" do
    context 'with data-group' do
      it 'removes unpermitted Group references' do
        user = create(:user)
        group = create(:group, :private)

        link = reference_link(group: group.id, reference_type: 'user')
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 0
      end

      it 'allows permitted Group references' do
        user = create(:user)
        group = create(:group, :private)
        group.add_developer(user)

        link = reference_link(group: group.id, reference_type: 'user')
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 1
      end

      it 'handles invalid Group references' do
        link = reference_link(group: 12345, reference_type: 'user')

        expect { filter(link) }.not_to raise_error
      end
    end

    context 'with data-user' do
      it 'allows any User reference' do
        user = create(:user)

        link = reference_link(user: user.id, reference_type: 'user')
        doc = filter(link)

        expect(doc.css('a').length).to eq 1
      end
    end
  end
end
