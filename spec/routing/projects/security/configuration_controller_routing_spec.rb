# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::ConfigurationController, 'routing' do
  let(:base_params) { { namespace_id: 'gitlab', project_id: 'gitlabhq' } }

  before do
    allow(Project).to receive(:find_by_full_path).with('gitlab/gitlabhq', any_args).and_return(true)
  end

  it 'routes to #show' do
    expect(get('/gitlab/gitlabhq/-/security/configuration')).to route_to('projects/security/configuration#show', namespace_id: 'gitlab', project_id: 'gitlabhq')
  end
end
