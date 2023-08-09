# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'merge requests creations', feature_category: :code_review_workflow do
  describe 'GET /:namespace/:project/merge_requests/new' do
    include ProjectForksHelper

    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, group: group) }
    let_it_be(:user) { create(:user) }

    let(:get_params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        merge_request: {
          source_branch: 'two-commits',
          target_branch: 'master'
        }
      }
    end

    before_all do
      group.add_developer(user)
    end

    before do
      login_as(user)
    end

    def get_new(params = get_params)
      get namespace_project_new_merge_request_path(params)
    end

    describe 'GET new' do
      context 'without merge_request params' do
        it 'avoids N+1 DB queries even with forked projects' do
          control = ActiveRecord::QueryRecorder.new(skip_cached: false) { get_new }

          5.times { fork_project(project, user) }

          expect { get_new }.not_to exceed_query_limit(control)
        end

        it 'renders branch selection screen' do
          get_new(get_params.except(:merge_request))

          expect(response).to be_successful
          expect(response).to render_template(partial: '_new_compare')
        end
      end

      context 'with merge_request params' do
        it 'renders new merge request widget template' do
          get_new

          expect(response).to be_successful
          expect(response).to render_template(partial: '_new_submit')
          expect(response).not_to render_template(partial: '_new_compare')
        end

        context 'when existing merge request with same target and source branches' do
          let_it_be(:existing_mr) { create(:merge_request) }

          it 'renders branch selection screen' do
            allow_next_instance_of(MergeRequest) do |instance|
              allow(instance).to receive(:existing_mrs_targeting_same_branch).and_return([existing_mr])
            end

            get_new

            expect(response).to be_successful
            expect(response).to render_template(partial: '_new_compare')
          end
        end
      end
    end

    it_behaves_like "observability csp policy", Projects::MergeRequests::CreationsController do
      let(:tested_path) do
        project_new_merge_request_path(project, merge_request: {
          title: 'Some feature',
          source_branch: 'fix',
          target_branch: 'feature',
          target_project: project,
          source_project: project
        })
      end
    end
  end
end
