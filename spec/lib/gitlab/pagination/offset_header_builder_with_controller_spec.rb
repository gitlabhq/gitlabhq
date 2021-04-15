# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::OffsetHeaderBuilder, type: :controller do
  controller(ActionController::Base) do
    def index
      relation = Project.where(archived: params[:archived]).page(params[:page]).order(:id).per(1)

      params_for_pagination = { archived: params[:archived], page: params[:page] }

      Gitlab::Pagination::OffsetHeaderBuilder.new(
        request_context: self,
        per_page: relation.limit_value,
        page: relation.current_page,
        next_page: relation.next_page,
        prev_page: relation.prev_page,
        params: params_for_pagination
      ).execute(exclude_total_headers: true, data_without_counts: true)

      render json: relation.map(&:id)
    end
  end

  let_it_be(:projects) { create_list(:project, 2, archived: true).sort_by(&:id) }

  describe 'pagination' do
    it 'returns correct result for the first page' do
      get :index, params: { page: 1, archived: true }

      expect(json_response).to eq([projects.first.id])
    end

    it 'returns correct result for the second page' do
      get :index, params: { page: 2, archived: true }

      expect(json_response).to eq([projects.last.id])
    end
  end

  describe 'pagination heders' do
    it 'adds next page header' do
      get :index, params: { page: 1, archived: true }

      expect(response.headers['X-Next-Page']).to eq('2')
    end

    it 'adds only the specified params to the lnk' do
      get :index, params: { page: 1, archived: true, some_param: '1' }

      expect(response.headers['Link']).not_to include('some_param')
    end
  end
end
