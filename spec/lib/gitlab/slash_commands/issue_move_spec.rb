# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::IssueMove, :service do
  describe '#match' do
    shared_examples_for 'move command' do |text_command|
      it 'can be parsed to extract the needed fields' do
        match_data = described_class.match(text_command)

        expect(match_data['iid']).to eq('123456')
        expect(match_data['project_path']).to eq('gitlab/gitlab-ci')
      end
    end

    it_behaves_like 'move command', 'issue move #123456 to gitlab/gitlab-ci'
    it_behaves_like 'move command', 'issue move #123456 gitlab/gitlab-ci'
    it_behaves_like 'move command', 'issue move #123456 gitlab/gitlab-ci '
    it_behaves_like 'move command', 'issue move 123456 to gitlab/gitlab-ci'
    it_behaves_like 'move command', 'issue move 123456 gitlab/gitlab-ci'
    it_behaves_like 'move command', 'issue move 123456 gitlab/gitlab-ci '
  end

  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue) }
    let_it_be(:chat_name) { create(:chat_name, user: user) }
    let_it_be(:project) { issue.project }
    let_it_be(:other_project) { create(:project, namespace: project.namespace) }

    before do
      [project, other_project].each { |prj| prj.add_maintainer(user) }
    end

    subject { described_class.new(project, chat_name) }

    def process_message(message)
      subject.execute(described_class.match(message))
    end

    context 'when the user can move the issue' do
      context 'when the move fails' do
        it 'returns the error message' do
          message = "issue move #{issue.iid} #{project.full_path}"

          expect(process_message(message)).to include(response_type: :ephemeral,
            text: a_string_matching('Cannot move issue'))
        end
      end

      context 'when the move succeeds' do
        let(:message) { "issue move #{issue.iid} #{other_project.full_path}" }

        it 'moves the issue to the new destination' do
          expect { process_message(message) }.to change { Issue.count }.by(1)

          new_issue = issue.reload.moved_to

          expect(new_issue.state).to eq('opened')
          expect(new_issue.project_id).to eq(other_project.id)
          expect(new_issue.author_id).to eq(issue.author_id)

          expect(issue.state).to eq('closed')
          expect(issue.project_id).to eq(project.id)
        end

        it 'returns the new issue' do
          expect(process_message(message))
            .to include(response_type: :in_channel,
              attachments: [a_hash_including(title_link: a_string_including(other_project.full_path))])
        end

        it 'mentions the old issue' do
          expect(process_message(message))
            .to include(attachments: [a_hash_including(pretext: a_string_including(project.full_path))])
        end
      end
    end

    context 'when the issue does not exist' do
      it 'returns not found' do
        message = "issue move #{issue.iid.succ} #{other_project.full_path}"

        expect(process_message(message)).to include(response_type: :ephemeral,
          text: a_string_matching('not found'))
      end
    end

    context 'when the target project does not exist' do
      it 'returns not found' do
        message = "issue move #{issue.iid} #{other_project.full_path}/foo"

        expect(process_message(message)).to include(response_type: :ephemeral,
          text: a_string_matching('not found'))
      end
    end

    context 'when the user cannot see the target project', :sidekiq_inline do
      it 'returns not found' do
        message = "issue move #{issue.iid} #{other_project.full_path}"
        other_project.team.truncate

        expect(process_message(message)).to include(response_type: :ephemeral,
          text: a_string_matching('not found'))
      end
    end

    context 'when the user does not have the required permissions on the target project' do
      it 'returns the error message' do
        message = "issue move #{issue.iid} #{other_project.full_path}"
        other_project.team.truncate
        other_project.team.add_guest(user)

        expect(process_message(message)).to include(response_type: :ephemeral,
          text: a_string_matching('Cannot move issue'))
      end
    end
  end
end
