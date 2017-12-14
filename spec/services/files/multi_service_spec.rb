require "spec_helper"

describe Files::MultiService do
  subject { described_class.new(project, user, commit_params) }

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:branch_name) { project.default_branch }
  let(:action) { 'update' }

  let(:actions) do
    [
      {
        action: action,
        file_path: 'files/ruby/popen.rb',
        content: 'New content'
      }
    ]
  end

  let(:commit_params) do
    {
      commit_message: "Update File",
      branch_name: branch_name,
      start_branch: branch_name,
      actions: actions
    }
  end

  before do
    project.team << [user, :master]
  end

  describe '#execute' do
    context 'with a valid action' do
      it 'returns a hash with the :success status ' do
        results = subject.execute

        expect(results[:status]).to eq(:success)
      end
    end

    context 'with an invalid action' do
      let(:action) { 'rename' }

      it 'returns a hash with the :error status ' do
        results = subject.execute

        expect(results[:status]).to eq(:error)
        expect(results[:message]).to match(/Unknown action/)
      end
    end
  end
end
