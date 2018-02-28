require 'spec_helper'

describe CreateBranchService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    context 'when repository is empty' do
      let(:project) { create(:project_empty_repo) }

      it 'creates master branch' do
        service.execute('my-feature', 'master')

        expect(project.repository.branch_exists?('master')).to be_truthy
      end

      it 'creates my-feature branch' do
        service.execute('my-feature', 'master')

        expect(project.repository.branch_exists?('my-feature')).to be_truthy
      end
    end
  end
end
