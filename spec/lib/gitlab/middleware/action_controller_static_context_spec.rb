# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::ActionControllerStaticContext, feature_category: :error_budgets do
  # to check the end to end tests, go to spec/requests/application_controller_spec.rb

  let(:env) do
    # env mimicking a controller action parsed by the rails routes
    { 'action_dispatch.request.path_parameters' => { controller: "dashboard/groups", action: "index" } }
  end

  let(:app) { ->(_env) { [200, {}, ["Hello World"]] } }

  it 'populates context with static controller attributes' do
    described_class.new(app).call(env)

    expect(Labkit::Context.current.to_h).to include({
      'meta.feature_category' => 'groups_and_projects',
      'meta.caller_id' => 'Dashboard::GroupsController#index'
    })
  end
end
