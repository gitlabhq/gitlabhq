# frozen_string_literal: true

require 'spec_helper'

describe Issues::MoveService do
  let(:user) { create(:user) }
  let(:author) { create(:user) }
  let(:title) { 'Some issue' }
  let(:description) { 'Some issue description' }
  let(:group) { create(:group, :private) }
  let(:sub_group_1) { create(:group, :private, parent: group) }
  let(:sub_group_2) { create(:group, :private, parent: group) }
  let(:old_project) { create(:project, namespace: sub_group_1) }
  let(:new_project) { create(:project, namespace: sub_group_2) }

  let(:old_issue) do
    create(:issue, title: title, description: description, project: old_project, author: author)
  end

  subject(:move_service) do
    described_class.new(old_project, user)
  end

  shared_context 'user can move issue' do
    before do
      old_project.add_reporter(user)
      new_project.add_reporter(user)
    end
  end

  describe '#execute' do
    shared_context 'issue move executed' do
      let!(:award_emoji) { create(:award_emoji, awardable: old_issue) }

      let!(:new_issue) { move_service.execute(old_issue, new_project) }
    end

    context 'issue movable' do
      include_context 'user can move issue'

      context 'generic issue' do
        include_context 'issue move executed'

        it 'creates a new issue in a new project' do
          expect(new_issue.project).to eq new_project
        end

        it 'rewrites issue title' do
          expect(new_issue.title).to eq title
        end

        it 'rewrites issue description' do
          expect(new_issue.description).to eq description
        end

        it 'adds system note to old issue at the end' do
          expect(old_issue.notes.last.note).to start_with 'moved to'
        end

        it 'adds system note to new issue at the end' do
          expect(new_issue.notes.last.note).to start_with 'moved from'
        end

        it 'closes old issue' do
          expect(old_issue.closed?).to be true
        end

        it 'persists new issue' do
          expect(new_issue.persisted?).to be true
        end

        it 'persists all changes' do
          expect(old_issue.changed?).to be false
          expect(new_issue.changed?).to be false
        end

        it 'preserves author' do
          expect(new_issue.author).to eq author
        end

        it 'creates a new internal id for issue' do
          expect(new_issue.iid).to be 1
        end

        it 'marks issue as moved' do
          expect(old_issue.moved?).to eq true
          expect(old_issue.moved_to).to eq new_issue
        end

        it 'preserves create time' do
          expect(old_issue.created_at).to eq new_issue.created_at
        end

        it 'moves the award emoji' do
          expect(old_issue.award_emoji.first.name).to eq new_issue.reload.award_emoji.first.name
        end
      end

      context 'issue with assignee' do
        let(:assignee) { create(:user) }

        before do
          old_issue.assignees = [assignee]
        end

        it 'preserves assignee with access to the new issue' do
          new_project.add_reporter(assignee)

          new_issue = move_service.execute(old_issue, new_project)

          expect(new_issue.assignees).to eq([assignee])
        end

        it 'ignores assignee without access to the new issue' do
          new_issue = move_service.execute(old_issue, new_project)

          expect(new_issue.assignees).to be_empty
        end
      end

      context 'moving to same project' do
        let(:new_project) { old_project }

        it 'raises error' do
          expect { move_service.execute(old_issue, new_project) }
            .to raise_error(StandardError, /Cannot move issue/)
        end
      end

      context 'project issue hooks' do
        let!(:hook) { create(:project_hook, project: old_project, issues_events: true) }

        it 'executes project issue hooks' do
          allow_any_instance_of(WebHookService).to receive(:execute)

          # Ideally, we'd test that `WebHookWorker.jobs.size` increased by 1,
          # but since the entire spec run takes place in a transaction, we never
          # actually get to the `after_commit` hook that queues these jobs.
          expect { move_service.execute(old_issue, new_project) }
            .not_to raise_error # Sidekiq::Worker::EnqueueFromTransactionError
        end
      end
    end

    describe 'move permissions' do
      let(:move) { move_service.execute(old_issue, new_project) }

      context 'user is reporter in both projects' do
        include_context 'user can move issue'
        it { expect { move }.not_to raise_error }
      end

      context 'user is reporter only in new project' do
        before do
          new_project.add_reporter(user)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'user is reporter only in old project' do
        before do
          old_project.add_reporter(user)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'user is reporter in one project and guest in another' do
        before do
          new_project.add_guest(user)
          old_project.add_reporter(user)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'issue has already been moved' do
        include_context 'user can move issue'

        let(:moved_to_issue) { create(:issue) }

        let(:old_issue) do
          create(:issue, project: old_project, author: author,
                         moved_to: moved_to_issue)
        end

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end

      context 'issue is not persisted' do
        include_context 'user can move issue'
        let(:old_issue) { build(:issue, project: old_project, author: author) }

        it { expect { move }.to raise_error(StandardError, /permissions/) }
      end
    end
  end
end
