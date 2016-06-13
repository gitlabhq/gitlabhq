require 'spec_helper'

describe Gitlab::AuthorityAnalyzer, lib: true do
  describe '#calculate' do
    let(:project) { create(:project) }
    let(:author) { create(:user) }
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }
    let(:merge_request) { create(:merge_request, target_project: project, source_project: project, author: author) }
    let(:files) { [double(:file, deleted_file: true, old_path: 'foo')] }

    let(:commits) do
      [
        double(:commit, author: author),
        double(:commit, author: user_a),
        double(:commit, author: user_a),
        double(:commit, author: user_b),
        double(:commit, author: author)
      ]
    end

    let(:approvers) { Gitlab::AuthorityAnalyzer.new(merge_request).calculate(number_of_approvers) }

    before do
      merge_request.compare = double(:compare, diffs: files)
      allow(merge_request.target_project.repository).to receive(:commits).and_return(commits)
    end

    context 'when there are fewer contributors than requested' do
      let(:number_of_approvers) { 5 }

      it 'returns the full number of users' do
        expect(approvers.length).to eq(2)
      end
    end

    context 'when there are more contributors than requested' do
      let(:number_of_approvers) { 1 }

      it 'returns only the top n contributors' do
        expect(approvers).to contain_exactly(user_a)
      end
    end
  end
end
