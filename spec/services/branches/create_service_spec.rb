# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Branches::CreateService do
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
        err_msg = 'Failed to create branch \'new-feature\': invalid reference name \'unknown\''
        result = service.execute('new-feature', 'unknown')

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq(err_msg)
      end
    end

    context 'when an ambiguous branch name is provided' do
      it 'returns an error that branch could not be created' do
        err_msg = 'Failed to create branch \'feature\': 13:reference is ambiguous.'

        service.execute('feature/widget', 'master')
        result = service.execute('feature', 'master')

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq(err_msg)
      end
    end

    it 'logs and returns an error if there is a PreReceiveError exception' do
      error_message = 'pre receive error'
      raw_message = "GitLab: #{error_message}"
      pre_receive_error = Gitlab::Git::PreReceiveError.new(raw_message)

      allow(project.repository).to receive(:add_branch).and_raise(pre_receive_error)

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        pre_receive_error,
        pre_receive_message: raw_message,
        branch_name: 'new-feature',
        ref: 'unknown'
      )

      result = service.execute('new-feature', 'unknown')

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq(error_message)
    end
  end
end
