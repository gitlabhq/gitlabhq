# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeleteService do
  let_it_be(:admin) { create(:admin) }

  let(:project) { create(:project, path: "my.project")}
  let!(:domain) { create(:pages_domain, project: project) }
  let(:service) { described_class.new(project, admin)}

  before do
    project.mark_pages_as_deployed
  end

  it 'deletes published pages', :sidekiq_inline do
    expect(project.pages_deployed?).to be(true)

    expect_next_instance_of(Gitlab::PagesTransfer) do |pages_transfer|
      expect(pages_transfer).to receive(:rename_project).and_return true
    end

    expect(PagesWorker).to receive(:perform_in).with(5.minutes, :remove, project.namespace.full_path, anything)

    service.execute

    expect(project.pages_deployed?).to be(false)
  end

  it "doesn't remove anything from the legacy storage", :sidekiq_inline do
    allow(Settings.pages.local_store).to receive(:enabled).and_return(false)

    expect(project.pages_deployed?).to be(true)
    expect(PagesWorker).not_to receive(:perform_in)

    service.execute

    expect(project.pages_deployed?).to be(false)
  end

  it 'deletes all domains', :sidekiq_inline do
    expect(project.pages_domains.count).to eq(1)

    service.execute

    expect(project.reload.pages_domains.count).to eq(0)
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

  it 'marks pages as not deployed, deletes domains and schedules worker to remove pages from disk' do
    expect(project.pages_deployed?).to eq(true)
    expect(project.pages_domains.count).to eq(1)

    service.execute

    expect(project.pages_deployed?).to eq(false)
    expect(project.pages_domains.count).to eq(0)

    expect_next_instance_of(Gitlab::PagesTransfer) do |pages_transfer|
      expect(pages_transfer).to receive(:rename_project).and_return true
    end

    Sidekiq::Worker.drain_all
  end
end
