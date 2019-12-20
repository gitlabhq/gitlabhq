# frozen_string_literal: true

require 'spec_helper'

describe Branches::CreateService do
  let(:user) { create(:user) }

  subject(:service) { described_class.new(project, user) }

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

    context 'when creating a branch fails' do
      let(:project) { create(:project_empty_repo) }

      before do
        allow(project.repository).to receive(:add_branch).and_return(false)
      end

      it 'returns an error with the branch name' do
        result = service.execute('my-feature', 'master')

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Invalid reference name: my-feature")
      end
    end
  end
end
