# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Branches::CreateService, :use_clean_rails_redis_caching do
  subject(:service) { described_class.new(project, user) }

  let_it_be(:project) { create(:project_empty_repo) }
  let_it_be(:user) { create(:user) }

  describe '#bulk_create' do
    subject { service.bulk_create(branches) }

    let_it_be(:project) { create(:project, :custom_repo, files: { 'foo/a.txt' => 'foo' }) }

    let(:branches) { { 'branch' => 'master', 'another_branch' => 'master' } }

    it 'creates two branches' do
      expect(subject[:status]).to eq(:success)
      expect(subject[:branches].map(&:name)).to match_array(%w[branch another_branch])

      expect(project.repository.branch_exists?('branch')).to be_truthy
      expect(project.repository.branch_exists?('another_branch')).to be_truthy
    end

    context 'when branches are empty' do
      let(:branches) { {} }

      it 'is successful' do
        expect(subject[:status]).to eq(:success)
        expect(subject[:branches]).to eq([])
      end
    end

    context 'when incorrect reference is provided' do
      let(:branches) { { 'new-feature' => 'unknown' } }

      before do
        allow(project.repository).to receive(:add_branch).and_return(false)
      end

      it 'returns an error with a reference name' do
        err_msg = 'Failed to create branch \'new-feature\': invalid reference name \'unknown\''

        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to match_array([err_msg])
      end
    end

    context 'when branch already exists' do
      let(:branches) { { 'master' => 'master' } }

      it 'returns an error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to match_array(['Branch already exists'])
      end
    end

    context 'when an ambiguous branch name is provided' do
      let(:branches) { { 'ambiguous/test' => 'master', 'ambiguous' => 'master' } }

      it 'returns an error that branch could not be created' do
        err_msg = 'Failed to create branch \'ambiguous\': 13:reference is ambiguous.'

        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to match_array([err_msg])
      end
    end

    context 'when PreReceiveError exception' do
      let(:branches) { { 'error' => 'master' } }

      it 'logs and returns an error if there is a PreReceiveError exception' do
        error_message = 'pre receive error'
        raw_message = "GitLab: #{error_message}"
        pre_receive_error = Gitlab::Git::PreReceiveError.new(raw_message)

        allow(project.repository).to receive(:add_branch).and_raise(pre_receive_error)

        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          pre_receive_error,
          pre_receive_message: raw_message,
          branch_name: 'error',
          ref: 'master'
        )

        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to match_array([error_message])
      end
    end

    context 'when multiple errors occur' do
      let(:branches) { { 'master' => 'master', '' => 'master', 'failed_branch' => 'master' } }

      it 'returns all errors' do
        allow(project.repository).to receive(:add_branch).with(user, 'failed_branch', 'master').and_return(false)

        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to match_array(
          [
            'Branch already exists',
            'Branch name is invalid',
            "Failed to create branch 'failed_branch': invalid reference name 'master'"
          ]
        )
      end
    end

    context 'without N+1 for Redis cache' do
      let(:branches) { { 'branch1' => 'master', 'branch2' => 'master', 'branch3' => 'master' } }

      it 'does not trigger Redis recreation' do
        project.repository.expire_branches_cache

        control = RedisCommands::Recorder.new(pattern: ':branch_names:') { subject }

        expect(control.by_command(:sadd).count).to eq(1)
      end
    end
  end

  describe '#execute' do
    context 'when repository is empty' do
      it 'creates master branch' do
        result = service.execute('my-feature', 'master')

        expect(result[:status]).to eq(:success)
        expect(result[:branch].name).to eq('my-feature')
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

      expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
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
