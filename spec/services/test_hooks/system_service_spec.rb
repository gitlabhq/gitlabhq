# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestHooks::SystemService, feature_category: :code_testing do
  include AfterNextHelpers

  describe '#execute' do
    let_it_be(:project) { create(:project, :small_repo) }

    let(:hook)    { create(:system_hook) }
    let(:service) { described_class.new(hook, project.first_owner, trigger) }
    let(:success_result) { { status: :success, http_status: 200, message: 'ok' } }

    before do
      allow(Project).to receive(:first).and_return(project)
    end

    context 'hook with not implemented test' do
      let(:trigger) { 'not_implemented_events' }

      it 'returns error message' do
        expect(hook).not_to receive(:execute)
        expect(service.execute).to have_attributes(status: :error, message: 'Testing not available for this hook')
      end
    end

    context 'push_events' do
      let(:trigger) { 'push_events' }
      let(:trigger_key) { :push_hooks }

      it 'executes hook' do
        expect(Gitlab::DataBuilder::Push).to receive(:sample_data).and_call_original

        expect(hook).to receive(:execute).with(Gitlab::DataBuilder::Push::SAMPLE_DATA, trigger_key, force: true).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'tag_push_events' do
      let(:trigger) { 'tag_push_events' }
      let(:trigger_key) { :tag_push_hooks }

      it 'executes hook' do
        allow(project.repository).to receive(:tags).and_return(['tag'])
        expect(Gitlab::DataBuilder::Push).to receive(:sample_data).and_call_original

        expect(hook).to receive(:execute).with(Gitlab::DataBuilder::Push::SAMPLE_DATA, trigger_key, force: true).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'repository_update_events' do
      let(:trigger) { 'repository_update_events' }
      let(:trigger_key) { :repository_update_hooks }

      it 'executes hook' do
        expect(Gitlab::DataBuilder::Repository).to receive(:sample_data).and_call_original

        expect(hook).to receive(:execute).with(Gitlab::DataBuilder::Repository::SAMPLE_DATA, trigger_key, force: true).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'merge_requests_events' do
      let(:trigger) { 'merge_requests_events' }
      let(:trigger_key) { :merge_request_hooks }
      let(:merge_request) { build(:merge_request) }
      let(:sample_data) { { data: 'sample' } }

      it 'returns error message if the user does not have any repository with a merge request' do
        expect(hook).not_to receive(:execute)
        expect(service.execute).to have_attributes(status: :error, message: 'Ensure one of your projects has merge requests.')
      end

      it 'executes hook' do
        expect(MergeRequest).to receive(:of_projects).and_return([merge_request])
        expect(merge_request).to receive(:to_hook_data).and_return(sample_data)
        expect(hook).to receive(:execute).with(sample_data, trigger_key, force: true).and_return(success_result)
        expect(service.execute).to include(success_result)
      end

      context 'with merge requests in different organizations' do
        let_it_be(:user) { create(:user) }
        let_it_be(:hook_organization) { create(:organization) }
        let_it_be(:other_organization) { create(:organization) }

        let(:hook) { create(:system_hook, organization: hook_organization) }
        let(:service) { described_class.new(hook, user, trigger) }

        context 'when only a project in another organization has a merge request' do
          let_it_be(:other_project) { create(:project, organization: other_organization) }
          let_it_be(:other_merge_request) { create(:merge_request, source_project: other_project) }

          before_all do
            other_project.add_maintainer(user)
          end

          it 'returns an error and does not execute the hook' do
            expect(hook).not_to receive(:execute)
            expect(service.execute).to have_attributes(
              status: :error, message: 'Ensure one of your projects has merge requests.')
          end
        end

        context 'when projects in both organizations have merge requests' do
          let_it_be(:project_in_org) { create(:project, organization: hook_organization) }
          let_it_be(:merge_request_in_org) { create(:merge_request, source_project: project_in_org) }
          # Created last so it would be picked by `MergeRequest#last` if projects were not scoped.
          let_it_be(:other_project) { create(:project, organization: other_organization) }
          let_it_be(:other_merge_request) { create(:merge_request, source_project: other_project) }

          before_all do
            other_project.add_maintainer(user)
            project_in_org.add_maintainer(user)
          end

          it 'builds the payload from the merge request in the hook organization' do
            expect(hook).to receive(:execute) do |data, hook_trigger, force:|
              expect(data.dig(:object_attributes, :id)).to eq(merge_request_in_org.id)
              expect(hook_trigger).to eq(trigger_key)
              expect(force).to be(true)

              success_result
            end

            expect(service.execute).to include(success_result)
          end
        end
      end
    end
  end
end
