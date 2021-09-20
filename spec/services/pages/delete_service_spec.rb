# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeleteService do
  let_it_be(:admin) { create(:admin) }

  let(:project) { create(:project, path: "my.project")}
  let(:service) { described_class.new(project, admin)}

  before do
    project.mark_pages_as_deployed
  end

  it 'marks pages as not deployed' do
    expect do
      service.execute
    end.to change { project.reload.pages_deployed? }.from(true).to(false)
  end

  it 'deletes all domains' do
    domain = create(:pages_domain, project: project)
    unrelated_domain = create(:pages_domain)

    service.execute

    expect(PagesDomain.find_by_id(domain.id)).to eq(nil)
    expect(PagesDomain.find_by_id(unrelated_domain.id)).to be
  end

  it 'schedules a destruction of pages deployments' do
    expect(DestroyPagesDeploymentsWorker).to(
      receive(:perform_async).with(project.id)
    )

    service.execute
  end

  it 'removes pages deployments', :sidekiq_inline do
    create(:pages_deployment, project: project)

    expect do
      service.execute
    end.to change { PagesDeployment.count }.by(-1)
  end
end
