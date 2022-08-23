# frozen_string_literal: true

# Shared examples for resource routes.
#
# By default it tests all the default REST actions: index, create, new, edit,
# show, update, and destroy. You can remove actions by customizing the
# `actions` variable.
#
# The subject is expected to be an instance of the controller under test.
#
# It also expects a `base_path` variable to be available which defines the
# base path of the controller, and a `base_params` variable which
# defines the route params the base path maps to.
#
# Examples
#
#   # Default behavior
#   describe Projects::CommitsController, 'routing' do
#     it_behaves_like 'resource routing' do
#       let(:base_path) { '/gitlab/gitlabhq/-/commits' }
#       let(:base_params) { { namespace_id: 'gitlab', project_id: 'gitlabhq' } }
#     end
#   end
#
#   # Customizing actions
#   it_behaves_like 'resource routing' do
#     let(:base_path) { '/gitlab/gitlabhq/-/commits' }
#
#     # Specify default actions
#     let(:actions) { [:index] }
#
#     # Add custom actions by passing a hash with action names
#     # as keys, and the HTTP method and path as values.
#     let(:additional_actions) do
#       {
#         preview_markdown: [:post, '/:id/preview_markdown'],
#       }
#     end
#   end
RSpec.shared_examples 'resource routing' do
  let(:controller) { described_class.controller_path }
  let(:id) { '123' }

  let(:default_actions) do
    {
      index: [:get, ''],
      show: [:get, '/:id'],
      new: [:get, '/new'],
      create: [:post, ''],
      edit: [:get, '/:id/edit'],
      update: [:put, '/:id'],
      destroy: [:delete, '/:id']
    }
  end

  let(:actions) { default_actions.keys }
  let(:additional_actions) { {} }

  it 'routes resource actions', :aggregate_failures do
    selected_actions = default_actions.slice(*actions).merge(additional_actions)

    selected_actions.each do |action, (method, action_path)|
      expected_params = base_params.merge(controller: controller.to_s, action: action.to_s)

      if action_path.include?(':id')
        action_path = action_path.sub(':id', id)
        expected_params[:id] = id
      end

      expect(public_send(method, "#{base_path}#{action_path}")).to route_to(expected_params)
    end
  end
end
