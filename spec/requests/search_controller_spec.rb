# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchController, type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, :repository, :wiki_repo, name: 'awesome project', group: group) }

  before_all do
    login_as(user)
  end

  def send_search_request(params)
    get search_path, params: params
  end

  shared_examples 'an efficient database result' do
    it 'avoids N+1 database queries' do
      create(object, *creation_traits, creation_args)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { send_search_request(params) }
      create_list(object, 3, *creation_traits, creation_args)

      expect { send_search_request(params) }.not_to exceed_all_query_limit(control).with_threshold(threshold)
    end
  end

  describe 'GET /search' do
    let(:creation_traits) { [] }

    context 'for issues scope' do
      let(:object) { :issue }
      let(:creation_args) { { project: project } }
      let(:params) { { search: '*', scope: 'issues' } }
      let(:threshold) { 0 }

      it_behaves_like 'an efficient database result'
    end

    context 'for merge_request scope' do
      let(:creation_traits) { [:unique_branches] }
      let(:object) { :merge_request }
      let(:creation_args) { { source_project: project } }
      let(:params) { { search: '*', scope: 'merge_requests' } }
      let(:threshold) { 0 }

      it_behaves_like 'an efficient database result'
    end

    context 'for project scope' do
      let(:creation_traits) { [:public] }
      let(:object) { :project }
      let(:creation_args) { {} }
      let(:params) { { search: '*', scope: 'projects' } }
      # some N+1 queries still exist
      # each project requires 3 extra queries
      #   - one count for forks
      #   - one count for open MRs
      #   - one count for open Issues
      let(:threshold) { 9 }

      it_behaves_like 'an efficient database result'
    end
  end
end
