require 'spec_helper'

describe MergeRequests::CreateService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:assignee) { create(:user) }

  describe '#execute' do
    context 'valid params' do
      let(:opts) do
        {
          title: 'Awesome merge_request',
          description: 'please fix',
          source_branch: 'feature',
          target_branch: 'master',
          force_remove_source_branch: '1'
        }
      end

      let(:service) { described_class.new(project, user, opts) }

      before do
        project.team << [user, :master]
        project.team << [assignee, :developer]
        allow(service).to receive(:execute_hooks)

        @merge_request = service.execute
      end

      it { expect(@merge_request).to be_valid }
      it { expect(@merge_request.title).to eq('Awesome merge_request') }
      it { expect(@merge_request.assignee).to be_nil }
      it { expect(@merge_request.merge_params['force_remove_source_branch']).to eq('1') }

      it 'executes hooks with default action' do
        expect(service).to have_received(:execute_hooks).with(@merge_request)
      end

      it 'does not creates todos' do
        attributes = {
          project: project,
          target_id: @merge_request.id,
          target_type: @merge_request.class.name
        }

        expect(Todo.where(attributes).count).to be_zero
      end

      context 'when merge request is assigned to someone' do
        let(:opts) do
          {
            title: 'Awesome merge_request',
            description: 'please fix',
            source_branch: 'feature',
            target_branch: 'master',
            assignee: assignee
          }
        end

        it { expect(@merge_request.assignee).to eq assignee }

        it 'creates a todo for new assignee' do
          attributes = {
            project: project,
            author: user,
            user: assignee,
            target_id: @merge_request.id,
            target_type: @merge_request.class.name,
            action: Todo::ASSIGNED,
            state: :pending
          }

          expect(Todo.where(attributes).count).to eq 1
        end
      end
    end

    it_behaves_like 'new issuable record that supports slash commands' do
      let(:default_params) do
        {
          source_branch: 'feature',
          target_branch: 'master'
        }
      end
    end

    context 'while saving references to issues that the created merge request closes' do
      let(:first_issue) { create(:issue, project: project) }
      let(:second_issue) { create(:issue, project: project) }

      let(:opts) do
        {
          title: 'Awesome merge_request',
          source_branch: 'feature',
          target_branch: 'master',
          force_remove_source_branch: '1'
        }
      end

      before do
        project.team << [user, :master]
        project.team << [assignee, :developer]
      end

      it 'creates a `MergeRequestsClosingIssues` record for each issue' do
        issue_closing_opts = opts.merge(description: "Closes #{first_issue.to_reference} and #{second_issue.to_reference}")
        service = described_class.new(project, user, issue_closing_opts)
        allow(service).to receive(:execute_hooks)
        merge_request = service.execute

        expect(merge_request.issues_closed).to match_array([first_issue, second_issue])
      end
    end
  end
end
