# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::IssueSerializer do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:project_label) { create(:label, project: project, title: 'bug') }
    let_it_be(:other_project_label) { create(:label, project: project, title: 'feature') }
    let_it_be(:group_label) { create(:group_label, group: group, title: 'dev') }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:user) { create(:user) }
    let_it_be(:issue_type) { WorkItems::Type.default_issue_type }

    let(:iid) { 5 }
    let(:key) { 'PROJECT-5' }
    let(:summary) { 'some title' }
    let(:description) { 'basic description' }
    let(:created_at) { '2020-01-01 20:00:00' }
    let(:updated_at) { '2020-01-10 20:00:00' }
    let(:assignee) { nil }
    let(:reporter) { nil }
    let(:jira_status) { 'new' }

    let(:parent_field) do
      { 'key' => 'FOO-2', 'id' => '1050', 'fields' => { 'summary' => 'parent issue FOO' } }
    end

    let(:priority_field) { { 'name' => 'Medium' } }
    let(:labels_field) { %w[bug dev backend frontend] }

    let(:fields) do
      {
        'parent' => parent_field,
        'priority' => priority_field,
        'labels' => labels_field
      }
    end

    let(:jira_issue) do
      double(
        id: '1234',
        key: key,
        summary: summary,
        description: description,
        created: created_at,
        updated: updated_at,
        assignee: assignee,
        reporter: reporter,
        status: double(statusCategory: { 'key' => jira_status }),
        fields: fields
      )
    end

    let(:params) { { iid: iid } }

    subject { described_class.new(project, jira_issue, current_user.id, issue_type, params).execute }

    let(:expected_description) do
      <<~MD
        basic description

        ---

        **Issue metadata**

        - Priority: Medium
        - Parent issue: [FOO-2] parent issue FOO
      MD
    end

    context 'attributes setting' do
      it 'sets the basic attributes' do
        expect(subject).to eq(
          iid: iid,
          project_id: project.id,
          namespace_id: project.project_namespace_id,
          description: expected_description.strip,
          title: "[#{key}] #{summary}",
          state_id: 1,
          updated_at: updated_at,
          created_at: created_at,
          author_id: current_user.id,
          assignee_ids: nil,
          label_ids: [project_label.id, group_label.id] + Label.reorder(id: :asc).last(2).pluck(:id),
          correct_work_item_type_id: issue_type.correct_id
        )
      end

      it 'creates a hash for valid issue' do
        expect(Issue.new(subject)).to be_valid
      end

      context 'labels' do
        it 'creates all missing labels (on project level)' do
          expect { subject }.to change { Label.count }.from(3).to(5)

          expect(Label.find_by(title: 'frontend').project).to eq(project)
          expect(Label.find_by(title: 'backend').project).to eq(project)
        end

        context 'when there are no new labels' do
          let(:labels_field) { %w[bug dev] }

          it 'assigns the labels to the Issue hash' do
            expect(subject[:label_ids]).to match_array([project_label.id, group_label.id])
          end

          it 'does not create new labels' do
            expect { subject }.not_to change { Label.count }.from(3)
          end
        end
      end

      context 'author' do
        let(:reporter) { double(attrs: { 'displayName' => 'Solver', 'accountId' => 'abcd' }) }

        context 'when reporter maps to a valid GitLab user' do
          it 'sets the issue author to the mapped user' do
            expect(Gitlab::JiraImport).to receive(:get_user_mapping).with(project.id, 'abcd')
              .and_return(user.id)

            expect(subject[:author_id]).to eq(user.id)
          end
        end

        context 'when reporter does not map to a valid Gitlab user' do
          it 'defaults the issue author to project creator' do
            expect(Gitlab::JiraImport).to receive(:get_user_mapping).with(project.id, 'abcd')
              .and_return(nil)

            expect(subject[:author_id]).to eq(current_user.id)
          end
        end

        context 'when reporter field is empty' do
          let(:reporter) { nil }

          it 'defaults the issue author to project creator' do
            expect(Gitlab::JiraImport).not_to receive(:get_user_mapping)

            expect(subject[:author_id]).to eq(current_user.id)
          end
        end

        context 'when reporter field is missing accountId' do
          let(:reporter) { double(attrs: { 'displayName' => 'Reporter' }) }

          it 'defaults the issue author to project creator' do
            expect(Gitlab::JiraImport).not_to receive(:get_user_mapping)

            expect(subject[:author_id]).to eq(current_user.id)
          end
        end
      end

      context 'assignee' do
        let(:assignee) { double(attrs: { 'displayName' => 'Solver', 'accountId' => '1234' }) }

        context 'when assignee maps to a valid GitLab user' do
          it 'sets the issue assignees to the mapped user' do
            expect(Gitlab::JiraImport).to receive(:get_user_mapping).with(project.id, '1234')
              .and_return(user.id)

            expect(subject[:assignee_ids]).to eq([user.id])
          end
        end

        context 'when assignee does not map to a valid GitLab user' do
          it 'leaves the assignee empty' do
            expect(Gitlab::JiraImport).to receive(:get_user_mapping).with(project.id, '1234')
              .and_return(nil)

            expect(subject[:assignee_ids]).to be_nil
          end
        end

        context 'when assginee field is empty' do
          let(:assignee) { nil }

          it 'leaves the assignee empty' do
            expect(Gitlab::JiraImport).not_to receive(:get_user_mapping)

            expect(subject[:assignee_ids]).to be_nil
          end
        end

        context 'when assginee field is missing accountId' do
          let(:assignee) { double(attrs: { 'displayName' => 'Solver' }) }

          it 'leaves the assignee empty' do
            expect(Gitlab::JiraImport).not_to receive(:get_user_mapping)

            expect(subject[:assignee_ids]).to be_nil
          end
        end

        context 'with jira server response' do
          let(:assignee) { double(attrs: { 'displayName' => 'Solver', 'key' => '1234' }) }

          context 'when assignee maps to a valid GitLab user' do
            it 'sets the issue assignees to the mapped user' do
              expect(Gitlab::JiraImport).to receive(:get_user_mapping).with(project.id, '1234')
                                                                      .and_return(user.id)

              expect(subject[:assignee_ids]).to eq([user.id])
            end
          end
        end
      end
    end

    context 'with done status' do
      let(:jira_status) { 'done' }

      it 'maps the status to closed' do
        expect(subject[:state_id]).to eq(2)
      end
    end

    context 'without the iid' do
      let(:params) { {} }

      it 'does not set the iid' do
        expect(subject[:iid]).to be_nil
      end
    end
  end
end
