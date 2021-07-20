# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteTemplateServicesDuplicatedByType do
  let(:services) { table(:services) }

  before do
    services.create!(template: true, type: 'JenkinsService')
    services.create!(template: true, type: 'JenkinsService')
    services.create!(template: true, type: 'JiraService')
    services.create!(template: true, type: 'JenkinsService')
  end

  it 'deletes service templates duplicated by type except the one with the lowest ID' do
    jenkins_integration_id = services.where(type: 'JenkinsService').order(:id).pluck(:id).first
    jira_integration_id = services.where(type: 'JiraService').pluck(:id).first

    migrate!

    expect(services.pluck(:id)).to contain_exactly(jenkins_integration_id, jira_integration_id)
  end
end
