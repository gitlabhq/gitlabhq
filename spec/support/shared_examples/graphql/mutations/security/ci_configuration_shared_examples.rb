# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples_for 'graphql mutations security ci configuration' do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user) }

  let(:branch) do
    "set-secret-config"
  end

  let(:success_path) do
    "http://127.0.0.1:3000/root/demo-historic-secrets/-/merge_requests/new?"
  end

  let(:service_response) do
    ServiceResponse.success(payload: { branch: branch, success_path: success_path })
  end

  let(:error) { "An error occured!" }

  let(:service_error_response) do
    ServiceResponse.error(message: error)
  end

  specify { expect(described_class).to require_graphql_authorizations(:push_code) }

  describe '#resolve' do
    let(:result) { subject }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when user does not have enough permissions' do
      before do
        project.add_guest(user)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user is a maintainer of a different project' do
      before do
        create(:project_empty_repo).add_maintainer(user)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user does not have permission to create a new branch' do
      let(:error_message) { 'You are not allowed to create protected branches on this project.' }

      before do
        project.add_developer(user)

        allow_next_instance_of(::Files::MultiService) do |multi_service|
          allow(multi_service).to receive(:execute).and_raise(Gitlab::Git::PreReceiveError.new("GitLab: #{error_message}"))
        end
      end

      it 'returns an array of errors' do
        expect(result).to match(
          branch: be_nil,
          success_path: be_nil,
          errors: match_array([error_message])
        )
      end
    end

    context 'when the user can create a merge request' do
      before do
        project.add_developer(user)
      end

      context 'when service successfully generates a path to create a new merge request' do
        before do
          allow_next_instance_of(service) do |service|
            allow(service).to receive(:execute).and_return(service_response)
          end
        end

        it 'returns a success path' do
          expect(result).to match(
            branch: branch,
            success_path: success_path,
            errors: []
          )
        end
      end

      context 'when service can not generate any path to create a new merge request' do
        before do
          allow_next_instance_of(service) do |service|
            allow(service).to receive(:execute).and_return(service_error_response)
          end
        end

        it 'returns an array of errors' do
          expect(result).to match(
            branch: be_nil,
            success_path: be_nil,
            errors: match_array([error])
          )
        end
      end
    end
  end
end
