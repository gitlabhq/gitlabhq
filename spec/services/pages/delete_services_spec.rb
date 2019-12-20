# frozen_string_literal: true

require 'spec_helper'

describe Pages::DeleteService do
  let_it_be(:project) { create(:project, path: "my.project")}
  let_it_be(:admin) { create(:admin) }
  let_it_be(:domain) { create(:pages_domain, project: project) }
  let_it_be(:service) { described_class.new(project, admin)}

  it 'deletes published pages' do
    expect_any_instance_of(Gitlab::PagesTransfer).to receive(:rename_project).and_return true
    expect(PagesWorker).to receive(:perform_in).with(5.minutes, :remove, project.namespace.full_path, anything)

    service.execute

    expect(project.reload.pages_metadatum.deployed?).to be(false)
  end

  it 'deletes all domains' do
    expect(project.pages_domains.count).to be 1

    service.execute

    expect(project.reload.pages_domains.count).to be 0
  end
end
