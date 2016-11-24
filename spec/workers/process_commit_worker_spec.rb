require 'spec_helper'

describe ProcessCommitWorker do
  let(:worker) { described_class.new }
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:issue) { create(:issue, project: project, author: user) }
  let(:commit) { project.commit }

  describe '#perform' do
    it 'does not process the commit when the project does not exist' do
      expect(worker).not_to receive(:close_issues)

      worker.perform(-1, user.id, commit.id)
    end

    it 'does not process the commit when the user does not exist' do
      expect(worker).not_to receive(:close_issues)

      worker.perform(project.id, -1, commit.id)
    end

    it 'does not process the commit when the commit no longer exists' do
      expect(worker).not_to receive(:close_issues)

      worker.perform(project.id, user.id, 'this-should-does-not-exist')
    end

    it 'processes the commit message' do
      expect(worker).to receive(:process_commit_message).and_call_original

      worker.perform(project.id, user.id, commit.id)
    end

    it 'updates the issue metrics' do
      expect(worker).to receive(:update_issue_metrics).and_call_original

      worker.perform(project.id, user.id, commit.id)
    end
  end

  describe '#process_commit_message' do
    context 'when pushing to the default branch' do
      it 'closes issues that should be closed per the commit message' do
        allow(commit).to receive(:safe_message).
          and_return("Closes #{issue.to_reference}")

        expect(worker).to receive(:close_issues).
          with(project, user, user, commit, [issue])

        worker.process_commit_message(project, commit, user, user, true)
      end
    end

    context 'when pushing to a non-default branch' do
      it 'does not close any issues' do
        allow(commit).to receive(:safe_message).
          and_return("Closes #{issue.to_reference}")

        expect(worker).not_to receive(:close_issues)

        worker.process_commit_message(project, commit, user, user, false)
      end
    end

    it 'creates cross references' do
      expect(commit).to receive(:create_cross_references!)

      worker.process_commit_message(project, commit, user, user)
    end
  end

  describe '#close_issues' do
    context 'when the user can update the issues' do
      it 'closes the issues' do
        worker.close_issues(project, user, user, commit, [issue])

        issue.reload

        expect(issue.closed?).to eq(true)
      end
    end

    context 'when the user can not update the issues' do
      it 'does not close the issues' do
        other_user = create(:user)

        worker.close_issues(project, other_user, other_user, commit, [issue])

        issue.reload

        expect(issue.closed?).to eq(false)
      end
    end
  end

  describe '#update_issue_metrics' do
    it 'updates any existing issue metrics' do
      allow(commit).to receive(:safe_message).
        and_return("Closes #{issue.to_reference}")

      worker.update_issue_metrics(commit, user)

      metric = Issue::Metrics.first

      expect(metric.first_mentioned_in_commit_at).to eq(commit.committed_date)
    end
  end
end
