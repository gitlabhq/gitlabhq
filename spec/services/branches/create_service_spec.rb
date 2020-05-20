# frozen_string_literal: true

require 'spec_helper'

describe Branches::CreateService do
  subject(:service) { described_class.new(project, user) }

  let_it_be(:project) { create(:project_empty_repo) }
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    context 'when repository is empty' do
      it 'creates master branch' do
        service.execute('my-feature', 'master')

        expect(project.repository.branch_exists?('master')).to be_truthy
      end

      it 'creates another-feature branch' do
        service.execute('another-feature', 'master')

        expect(project.repository.branch_exists?('another-feature')).to be_truthy
      end
    end

    context 'when branch already exists' do
      it 'returns an error' do
        result = service.execute('master', 'master')

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Branch already exists')
      end
    end

    context 'when incorrect reference is provided' do
      before do
        allow(project.repository).to receive(:add_branch).and_return(false)
      end

      it 'returns an error with a reference name' do
        result = service.execute('new-feature', 'unknown')

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Invalid reference name: unknown')
      end
    end
  end
end
