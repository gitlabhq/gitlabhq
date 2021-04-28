# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples_for 'services security ci configuration create service' do |skip_w_params|
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    let(:params) { {} }

    context 'user does not belong to project' do
      it 'returns an error status' do
        expect(result.status).to eq(:error)
        expect(result.payload[:success_path]).to be_nil
      end

      it 'does not track a snowplow event' do
        subject

        expect_no_snowplow_event
      end
    end

    context 'user belongs to project' do
      before do
        project.add_developer(user)
      end

      it 'does track the snowplow event' do
        subject

        expect_snowplow_event(**snowplow_event)
      end

      it 'raises exception if the user does not have permission to create a new branch' do
        allow(project).to receive(:repository).and_raise(Gitlab::Git::PreReceiveError, "You are not allowed to create protected branches on this project.")

        expect { subject }.to raise_error(Gitlab::Git::PreReceiveError)
      end

      context 'when exception is raised' do
        let_it_be(:project) { create(:project, :repository) }

        before do
          allow(project.repository).to receive(:add_branch).and_raise(StandardError, "The unexpected happened!")
        end

        context 'when branch was created' do
          before do
            allow(project.repository).to receive(:branch_exists?).and_return(true)
          end

          it 'tries to rm branch' do
            expect(project.repository).to receive(:rm_branch).with(user, branch_name)
            expect { subject }.to raise_error(StandardError)
          end
        end

        context 'when branch was not created' do
          before do
            allow(project.repository).to receive(:branch_exists?).and_return(false)
          end

          it 'does not try to rm branch' do
            expect(project.repository).not_to receive(:rm_branch)
            expect { subject }.to raise_error(StandardError)
          end
        end
      end

      context 'with no parameters' do
        it 'returns the path to create a new merge request' do
          expect(result.status).to eq(:success)
          expect(result.payload[:success_path]).to match(/#{Gitlab::Routing.url_helpers.project_new_merge_request_url(project, {})}(.*)description(.*)source_branch/)
        end
      end

      unless skip_w_params
        context 'with parameters' do
          let(:params) { non_empty_params }

          it 'returns the path to create a new merge request' do
            expect(result.status).to eq(:success)
            expect(result.payload[:success_path]).to match(/#{Gitlab::Routing.url_helpers.project_new_merge_request_url(project, {})}(.*)description(.*)source_branch/)
          end
        end
      end
    end
  end
end
