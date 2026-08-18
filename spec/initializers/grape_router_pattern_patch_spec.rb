# frozen_string_literal: true

require 'spec_helper'

# These examples encode the routing behaviour that
# config/initializers/grape_router_pattern_patch.rb preserves: a `type: Integer`
# path parameter must not constrain route matching.
#
# Without the patch, Grape turns a `type: Integer` path parameter into a
# digits-only route segment, so non-numeric and signed segments fail to match
# the route and return a generic `{"error":"404 Not Found"}` before reaching
# validation or the endpoint. The patch has been necessary to upgrade Grape
# from version 2.0 to 2.4, where the behaviour changed.
RSpec.describe 'Grape router pattern patch', feature_category: :api do
  include Rack::Test::Methods

  subject(:app) do
    Class.new(Grape::API) do
      format :json

      resource 'widgets/:id' do
        params do
          requires :id, type: Integer
        end
        get do
          error!({ message: '404 Widget Not Found' }, 404) unless params[:id] == 1

          { id: params[:id] }
        end
      end
    end
  end

  describe 'an Integer-typed path parameter' do
    it 'reaches the endpoint for a valid numeric id (coerced to Integer)', :aggregate_failures do
      get '/widgets/1'

      expect(last_response).to have_gitlab_http_status(:ok)
      expect(last_response.body).to eq('{"id":1}')
    end

    it 'reaches the endpoint (not a routing 404) for a valid-but-missing id', :aggregate_failures do
      get '/widgets/99999'

      expect(last_response).to have_gitlab_http_status(:not_found)
      expect(last_response.body).to eq('{"message":"404 Widget Not Found"}')
    end

    it 'returns a 400 validation error (not a routing 404) for a non-numeric id' do
      get '/widgets/an-invalid-id'

      expect(last_response).to have_gitlab_http_status(:bad_request)
    end

    it 'reaches the endpoint (not a routing 404) for a signed-integer id', :aggregate_failures do
      get '/widgets/-1' # Relies on mustermann's default capture constraint ([^/?#.], which permits -)

      expect(last_response).to have_gitlab_http_status(:not_found)
      expect(last_response.body).to eq('{"message":"404 Widget Not Found"}')
    end
  end
end
