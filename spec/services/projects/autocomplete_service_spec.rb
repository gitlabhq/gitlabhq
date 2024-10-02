# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AutocompleteService, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:owner) { create(:user, owner_of: project) }
  let_it_be(:issue) { create(:issue, project: project, title: 'Issue 1') }

  describe '#issues' do
    describe 'confidential issues' do
      let(:author) { create(:user) }
      let(:assignee) { create(:user) }
      let(:non_member) { create(:user) }
      let(:member) { create(:user) }
      let(:admin) { create(:admin) }
      let!(:security_issue_1) { create(:issue, :confidential, project: project, title: 'Security issue 1', author: author) }
      let!(:security_issue_2) { create(:issue, :confidential, title: 'Security issue 2', project: project, assignees: [assignee]) }

      it 'includes work item icons in list' do
        autocomplete = described_class.new(project, nil)
        issues = autocomplete.issues.map(&:icon_name)

        expect(issues).to include 'issue-type-issue'
      end

      it 'does not list project confidential issues for guests' do
        autocomplete = described_class.new(project, nil)
        issues = autocomplete.issues.map(&:iid)

        expect(issues).to include issue.iid
        expect(issues).not_to include security_issue_1.iid
        expect(issues).not_to include security_issue_2.iid
        expect(issues.count).to eq 1
      end

      it 'does not list project confidential issues for non project members' do
        autocomplete = described_class.new(project, non_member)
        issues = autocomplete.issues.map(&:iid)

        expect(issues).to include issue.iid
        expect(issues).not_to include security_issue_1.iid
        expect(issues).not_to include security_issue_2.iid
        expect(issues.count).to eq 1
      end

      it 'does not list project confidential issues for project members with guest role' do
        project.add_guest(member)

        autocomplete = described_class.new(project, non_member)
        issues = autocomplete.issues.map(&:iid)

        expect(issues).to include issue.iid
        expect(issues).not_to include security_issue_1.iid
        expect(issues).not_to include security_issue_2.iid
        expect(issues.count).to eq 1
      end

      it 'lists project confidential issues for author' do
        autocomplete = described_class.new(project, author)
        issues = autocomplete.issues.map(&:iid)

        expect(issues).to include issue.iid
        expect(issues).to include security_issue_1.iid
        expect(issues).not_to include security_issue_2.iid
        expect(issues.count).to eq 2
      end

      it 'lists project confidential issues for assignee' do
        autocomplete = described_class.new(project, assignee)
        issues = autocomplete.issues.map(&:iid)

        expect(issues).to include issue.iid
        expect(issues).not_to include security_issue_1.iid
        expect(issues).to include security_issue_2.iid
        expect(issues.count).to eq 2
      end

      it 'lists project confidential issues for project members' do
        project.add_developer(member)

        autocomplete = described_class.new(project, member)
        issues = autocomplete.issues.map(&:iid)

        expect(issues).to include issue.iid
        expect(issues).to include security_issue_1.iid
        expect(issues).to include security_issue_2.iid
        expect(issues.count).to eq 3
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'lists all project issues for admin', :enable_admin_mode do
          autocomplete = described_class.new(project, admin)
          issues = autocomplete.issues.map(&:iid)

          expect(issues).to include issue.iid
          expect(issues).to include security_issue_1.iid
          expect(issues).to include security_issue_2.iid
          expect(issues.count).to eq 3
        end
      end

      context 'when admin mode is disabled' do
        it 'does not list project confidential issues for admin' do
          autocomplete = described_class.new(project, admin)
          issues = autocomplete.issues.map(&:iid)

          expect(issues).to include issue.iid
          expect(issues).not_to include security_issue_1.iid
          expect(issues).not_to include security_issue_2.iid
          expect(issues.count).to eq 1
        end
      end
    end

    context 'when search param is given' do
      let_it_be(:issue_8) { create(:issue, project: project, iid: 8) }
      let_it_be(:issue_80) { create(:issue, project: project, iid: 80) }
      let_it_be(:issue_800) { create(:issue, project: project, iid: 800) }
      let_it_be(:issue_8000) { create(:issue, project: project, iid: 8000) }
      let_it_be(:issue_80000) { create(:issue, project: project, iid: 80000) }
      let_it_be(:issue_90000) { create(:issue, project: project, title: 'gitlab issue 8', iid: 90000) }

      it 'returns limited list of matching issues' do
        autocomplete = described_class.new(project, owner, { search: '8' })

        issue_iids = autocomplete.issues.map(&:iid)

        expect(issue_iids).to eq([90000, 80000, 8000, 800, 80])
      end
    end
  end

  describe '#milestones' do
    let(:user) { create(:user) }
    let!(:group_milestone1) { create(:milestone, group: group, due_date: '2017-01-01', title: 'Second Title') }
    let!(:group_milestone2) { create(:milestone, group: group, due_date: '2017-01-01', title: 'First Title') }
    let!(:project_milestone) { create(:milestone, project: project, due_date: '2016-01-01') }

    let(:milestone_titles) { described_class.new(project, user).milestones.map(&:title) }

    it 'includes project and group milestones and sorts them correctly' do
      expect(milestone_titles).to eq([project_milestone.title, group_milestone2.title, group_milestone1.title])
    end

    it 'does not include closed milestones' do
      group_milestone1.close

      expect(milestone_titles).to eq([project_milestone.title, group_milestone2.title])
    end

    it 'does not include milestones from other projects in the group' do
      other_project = create(:project, group: group)
      project_milestone.update!(project: other_project)

      expect(milestone_titles).to eq([group_milestone2.title, group_milestone1.title])
    end

    context 'with nested groups' do
      let(:subgroup) { create(:group, :public, parent: group) }
      let!(:subgroup_milestone) { create(:milestone, group: subgroup) }

      before do
        project.update!(namespace: subgroup)
      end

      it 'includes project milestones and all acestors milestones' do
        expect(milestone_titles).to match_array(
          [project_milestone.title, group_milestone2.title, group_milestone1.title, subgroup_milestone.title]
        )
      end
    end
  end

  describe '#wikis' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, group: group) }
    let_it_be(:wiki) { create(:project_wiki, project: project) }
    let_it_be(:page1) { create(:wiki_page, wiki: wiki, title: 'page1', content: 'content1') }
    let_it_be(:page2_template) { create(:wiki_page, wiki: wiki, title: 'templates/page2', content: 'content2') }
    let_it_be(:page3) { create(:wiki_page, wiki: wiki, title: 'page3', content: "---\ntitle: Real title\n---\ncontent3") }

    context 'when user can read wiki' do
      it 'returns wiki pages (except templates)' do
        service = described_class.new(project, user)
        results = service.wikis

        expect(results.size).to eq(2)
        expect(results.first).to include(path: "/#{project.full_path}/-/wikis/page1", slug: 'page1', title: 'page1')
      end

      it 'loads real title of the page from frontmatter if present' do
        service = described_class.new(project, user)
        results = service.wikis

        expect(results.size).to eq(2)
        expect(results.last).to include(path: "/#{project.full_path}/-/wikis/page3", slug: 'page3', title: 'Real title')
      end
    end

    context 'when user cannot read wiki' do
      it 'returns empty array' do
        project.project_feature.update!(wiki_access_level: ProjectFeature::PRIVATE)

        service = described_class.new(project, nil)
        results = service.wikis

        expect(results).to be_empty
      end
    end
  end

  describe '#contacts' do
    let_it_be(:user) { create(:user) }
    let_it_be(:contact_1) { create(:contact, group: group) }
    let_it_be(:contact_2) { create(:contact, group: group) }
    let_it_be(:contact_3) { create(:contact, :inactive, group: group) }

    let(:issue) { nil }

    subject { described_class.new(project, user).contacts(issue).as_json }

    before do
      group.add_developer(user)
    end

    it 'returns CRM contacts from group' do
      expected_contacts = [
        { 'id' => contact_1.id, 'email' => contact_1.email,
          'first_name' => contact_1.first_name, 'last_name' => contact_1.last_name, 'state' => contact_1.state },
        { 'id' => contact_2.id, 'email' => contact_2.email,
          'first_name' => contact_2.first_name, 'last_name' => contact_2.last_name, 'state' => contact_2.state },
        { 'id' => contact_3.id, 'email' => contact_3.email,
          'first_name' => contact_3.first_name, 'last_name' => contact_3.last_name, 'state' => contact_3.state }
      ]

      expect(subject).to match_array(expected_contacts)
    end

    context 'some contacts are already assigned to the issue' do
      let(:issue) { create(:issue, project: project) }

      before do
        issue.customer_relations_contacts << [contact_2, contact_3]
      end

      it 'marks already assigned contacts as set' do
        expected_contacts = [
          { 'id' => contact_1.id, 'email' => contact_1.email,
            'first_name' => contact_1.first_name, 'last_name' => contact_1.last_name, 'state' => contact_1.state, 'set' => false },
          { 'id' => contact_2.id, 'email' => contact_2.email,
            'first_name' => contact_2.first_name, 'last_name' => contact_2.last_name, 'state' => contact_2.state, 'set' => true },
          { 'id' => contact_3.id, 'email' => contact_3.email,
            'first_name' => contact_3.first_name, 'last_name' => contact_3.last_name, 'state' => contact_3.state, 'set' => true }
        ]

        expect(subject).to match_array(expected_contacts)
      end
    end
  end

  describe '#labels_as_hash' do
    def expect_labels_to_equal(labels, expected_labels)
      expect(labels.size).to eq(expected_labels.size)
      extract_title = ->(label) { label['title'] }
      expect(labels.map(&extract_title)).to match_array(expected_labels.map(&extract_title))
    end

    let(:user) { create(:user) }
    let(:group) { create(:group, :nested) }
    let!(:sub_group) { create(:group, parent: group) }
    let(:project) { create(:project, :public, group: group) }
    let(:issue) { create(:issue, project: project) }

    let!(:label1) { create(:label, project: project) }
    let!(:label2) { create(:label, project: project) }
    let!(:sub_group_label) { create(:group_label, group: sub_group) }
    let!(:parent_group_label) { create(:group_label, group: group.parent, group_id: group.id) }

    before do
      create(:group_member, group: group, user: user)
    end

    it 'returns labels from project and ancestor groups' do
      service = described_class.new(project, user)
      results = service.labels_as_hash(nil)
      expected_labels = [label1, label2, parent_group_label]

      expect_labels_to_equal(results, expected_labels)
    end

    context 'some labels are already assigned' do
      before do
        issue.labels << label1
      end

      it 'marks already assigned as set' do
        service = described_class.new(project, user)
        results = service.labels_as_hash(issue)
        expected_labels = [label1, label2, parent_group_label]

        expect_labels_to_equal(results, expected_labels)

        assigned_label_titles = issue.labels.map(&:title)
        results.each do |hash|
          if assigned_label_titles.include?(hash['title'])
            expect(hash[:set]).to eq(true)
          else
            expect(hash.key?(:set)).to eq(false)
          end
        end
      end
    end
  end

  describe '#commands' do
    subject(:commands) { described_class.new(project, owner).commands(issue) }

    context 'spend' do
      it 'params include timecategory' do
        expect(commands).to include(a_hash_including(
          name: :spend,
          params: ['time(1h30m | -1h30m) <date(YYYY-MM-DD)> <[timecategory:category-name]>']
        ))
      end

      context 'when timelog_category_quick_action feature flag is disabled' do
        before do
          stub_feature_flags(timelog_categories: false)
        end

        it 'params do not include timecategory' do
          expect(commands).to include(a_hash_including(
            name: :spend,
            params: ['time(1h30m | -1h30m) <date(YYYY-MM-DD)>']
          ))
        end
      end
    end
  end
end
