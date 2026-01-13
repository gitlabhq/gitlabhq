# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::ReferenceRedactorFilter, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:user) { create(:user) }

  it 'ignores non-GFM links' do
    html = %(See <a href="https://google.com/">Google</a>)
    doc = filter(html, current_user: build(:user))

    expect(doc.css('a').length).to eq 1
  end

  def reference_link(data)
    ActionController::Base.helpers.link_to('text', '', class: 'gfm', data: data)
  end

  it 'skips when the skip_redaction flag is set' do
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
        project = create(:project)
        link = reference_link(project: project.id, reference_type: 'test', original: 'original')

        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 0
        expect(doc.to_html).to eq('original')
      end

      it 'handles invalid references' do
        link = reference_link(project: non_existing_record_id, reference_type: 'test')

        expect { filter(link) }.not_to raise_error
      end
    end
  end

  context 'with data-issue' do
    context 'for confidential issues' do
      it 'removes references for non project members' do
        project = create(:project, :public)
        issue = create(:issue, :confidential, project: project)
        link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')

        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 0
      end

      it 'removes references for project members with guest role' do
        project = create(:project, :public)
        project.add_guest(user)
        issue = create(:issue, :confidential, project: project)

        link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 0
      end

      it 'allows references for author' do
        project = create(:project, :public)
        issue = create(:issue, :confidential, project: project, author: user)

        link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')
        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 1
      end

      it 'allows references for assignee' do
        project = create(:project, :public)
        issue = create(:issue, :confidential, project: project, assignees: [user])
        link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')

        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 1
      end

      it 'allows references for project members' do
        project = create(:project, :public)
        project.add_developer(user)
        issue = create(:issue, :confidential, project: project)
        link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')

        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 1
      end

      it 'allows references for admins' do
        admin = create(:admin)
        project = create(:project, :public)
        issue = create(:issue, :confidential, project: project)
        link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')

        doc = filter(link, current_user: admin)

        expect(doc.css('a').length).to eq 1
      end

      context "when a confidential issue is moved from a public project to a private one" do
        let(:public_project) { create(:project, :public) }
        let(:private_project) { create(:project, :private) }

        it 'removes references for author' do
          issue = create(:issue, :confidential, project: public_project, author: user)
          issue.update!(project: private_project) # move issue to private project
          link = reference_link(project: private_project.id, issue: issue.id, reference_type: 'issue')

          doc = filter(link, current_user: user)

          expect(doc.css('a').length).to eq 0
        end

        it 'removes references for assignee' do
          issue = create(:issue, :confidential, project: public_project, assignees: [user])
          issue.update!(project: private_project) # move issue to private project
          link = reference_link(project: private_project.id, issue: issue.id, reference_type: 'issue')

          doc = filter(link, current_user: user)

          expect(doc.css('a').length).to eq 0
        end

        it 'allows references for project members' do
          project = create(:project, :public)
          project_2 = create(:project, :private)
          project.add_developer(user)
          project_2.add_developer(user)
          issue = create(:issue, :confidential, project: project)
          issue.update!(project: project_2) # move issue to private project
          link = reference_link(project: project_2.id, issue: issue.id, reference_type: 'issue')

          doc = filter(link, current_user: user)

          expect(doc.css('a').length).to eq 1
        end
      end
    end

    it 'allows references for non confidential issues' do
      project = create(:project, :public)
      issue = create(:issue, project: project)
      link = reference_link(project: project.id, issue: issue.id, reference_type: 'issue')

      doc = filter(link, current_user: user)

      expect(doc.css('a').length).to eq 1
    end
  end

  context "for user references" do
    context 'with data-group' do
      let_it_be(:private_group) { create(:group, :private) }

      it 'removes unpermitted Group references' do
        link = reference_link(group: private_group.id, reference_type: 'user', original: 'original')

        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 0
        expect(doc.to_html).to eq('original')
      end

      it 'allows permitted Group references' do
        private_group.add_developer(user)
        link = reference_link(group: private_group.id, reference_type: 'user')

        doc = filter(link, current_user: user)

        expect(doc.css('a').length).to eq 1
      end

      it 'handles invalid Group references' do
        link = reference_link(group: 0, reference_type: 'user')

        expect { filter(link) }.not_to raise_error
      end
    end

    context 'with data-user' do
      it 'allows any User reference' do
        link = reference_link(user: user.id, reference_type: 'user')

        doc = filter(link)

        expect(doc.css('a').length).to eq 1
      end
    end
  end
end
