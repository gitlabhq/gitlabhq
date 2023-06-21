# frozen_string_literal: true

require 'spec_helper'

# Adds a missing test to provide full coverage for the patch
RSpec.describe 'ActionDispatch::Journey::Router Patch', feature_category: :database do
  before do
    load Rails.root.join('config/initializers/action_dispatch_journey_router.rb')
  end

  describe '#find_routes' do
    context 'when a route has additional constrains' do
      it 'does not raise an error' do
        stub_const('PagesController', Class.new(ApplicationController))

        set = ActionDispatch::Routing::RouteSet.new

        set.draw do
          get "*namespace_id/:project_id/bar",
            to: "pages#show",
            constraints: {
              namespace_id: %r{(?!api/)[a-zA-Z0-9_\\]+},
              project_id: /[a-zA-Z0-9]+/
            }

          get "/api/foo/bar", to: "pages#index"
        end

        params = set.recognize_path("/api/foo/bar", method: :get)

        expect(params[:controller]).to eq('pages')
        expect(params[:action]).to eq('index')
      end
    end
  end
end
