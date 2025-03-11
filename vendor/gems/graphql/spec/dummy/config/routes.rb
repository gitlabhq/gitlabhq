# frozen_string_literal: true
Rails.application.routes.draw do
  root to: "pages#show"
  mount GraphQL::Dashboard, at: "/dash", schema: "DummySchema"
end
