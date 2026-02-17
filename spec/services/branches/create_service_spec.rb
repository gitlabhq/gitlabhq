# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Branches::CreateService, :use_clean_rails_redis_caching, feature_category: :source_code_management do
  subject(:service) { described_class.new(project, user) }

  let_it_be(:project) { create(:project_empty_repo) }
  let_it_be(:user) { create(:user) }

  describe '#bulk_create' do
    subject { service.bulk_create(branches) }

    let_it_be(:project) { create(:project, :custom_repo, files: { 'foo/a.txt' => 'foo' }) }

    let(:branches) { { 'branch' => project.default_branch, 'another_branch' => project.default_branch } }

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
        allow(project.repository).to receive(:add_branch).and_raise(Gitlab::Git::Repository::InvalidRef)
      end

      it 'returns an error with a reference name' do
        err_msg = 'Failed to create branch \'new-feature\': invalid reference name \'unknown\''

        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to match_array([err_msg])
      end
    end

    context 'when branch already exists' do
      let(:branches) { { project.default_branch => project.default_branch } }

      it 'returns an error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to match_array(['Branch already exists'])
      end
    end

    context 'when PreReceiveError exception' do
      let(:branches) { { 'error' => project.default_branch } }

      it 'logs and returns an error if there is a PreReceiveError exception' do
        error_message = 'pre receive error'
        raw_message = "GitLab: #{error_message}"
        pre_receive_error = Gitlab::Git::PreReceiveError.new(raw_message)

        allow(project.repository).to receive(:add_branch).and_raise(pre_receive_error)

        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          pre_receive_error,
          pre_receive_message: raw_message,
          branch_name: 'error',
          ref: project.default_branch
        )

        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to match_array([error_message])
      end
    end

    context 'when multiple errors occur' do
      let(:branches) do
        { project.default_branch => project.default_branch, '' => project.default_branch,
          'failed_branch' => project.default_branch }
      end

      it 'returns all errors' do
        allow(project.repository).to receive(:add_branch).with(
          user,
          'failed_branch',
          project.default_branch,
          expire_cache: false,
          raise_on_invalid_ref: true
        ).and_raise(Gitlab::Git::Repository::InvalidRef)

        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to match_array(
          [
            'Branch already exists',
            'Branch name is invalid',
            "Failed to create branch 'failed_branch': invalid reference name '#{project.default_branch}'"
          ]
        )
      end
    end

    context 'without N+1 for Redis cache' do
      let(:branches) do
        { 'branch1' => project.default_branch, 'branch2' => project.default_branch,
          'branch3' => project.default_branch }
      end

      it 'does not trigger Redis recreation' do
        project.repository.expire_branches_cache

        control = RedisCommands::Recorder.new(pattern: ':branch_names:') { subject }

        expect(control).not_to exceed_redis_command_calls_limit(:sadd, 1)
      end
    end

    context 'without N+1 branch cache expiration' do
      let(:branches) do
        { 'branch_1' => project.default_branch, 'branch_2' => project.default_branch,
          'branch_3' => project.default_branch }
      end

      it 'triggers branch cache expiration only once' do
        expect(project.repository).to receive(:expire_branches_cache).once

        subject
      end

      context 'when branches were not added' do
        let(:branches) { { project.default_branch => project.default_branch } }

        it 'does not trigger branch expiration' do
          expect(project.repository).not_to receive(:expire_branches_cache)

          subject
        end
      end
    end
  end

  describe '#execute' do
    context 'when repository is empty' do
      it 'creates master branch' do
        result = service.execute('my-feature', project.default_branch)

        expect(result[:status]).to eq(:success)
        expect(result[:branch].name).to eq('my-feature')
        expect(project.repository.branch_exists?(project.default_branch)).to be_truthy
      end

      it 'creates another-feature branch' do
        service.execute('another-feature', project.default_branch)

        expect(project.repository.branch_exists?('another-feature')).to be_truthy
      end
    end

    context 'when provided ref is empty' do
      it 'returns an error' do
        result = service.execute('my-feature', '')

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Ref is missing')
      end
    end

    context 'when branch already exists' do
      it 'returns an error' do
        service.execute('my-branch', project.default_branch)
        result = service.execute('my-branch', project.default_branch)

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Branch already exists')
      end
    end

    context 'when incorrect reference is provided' do
      before do
        allow(project.repository).to receive(:add_branch).and_raise(Gitlab::Git::Repository::InvalidRef)
      end

      it 'returns an error with a reference name' do
        err_msg = 'Failed to create branch \'new-feature\': invalid reference name \'unknown\''
        result = service.execute('new-feature', 'unknown')

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

    context 'when there is a file directory conflict' do
      let(:branch_name) { 'foo/bar' }
      let(:expected_service_message) do
        "Failed to create branch '#{branch_name}': Branch name conflicts with existing branch hierarchy."
      end

      before do
        service.execute('foo', project.default_branch)
      end

      it 'raises the actual Gitaly error containing "file directory conflict"' do
        expect { project.repository.add_branch(user, branch_name, project.default_branch, raise_on_invalid_ref: true) }
          .to raise_error(Gitlab::Git::Repository::InvalidRef) do |e|
            expect(e.message).to include('file directory conflict')
          end
      end

      it 'returns a user friendly error message from the service' do
        result = service.execute(branch_name, project.default_branch)

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq(expected_service_message)
      end
    end
  end
end
