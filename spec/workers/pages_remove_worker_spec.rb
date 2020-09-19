# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesRemoveWorker do
  let_it_be(:project) { create(:project, path: "my.project")}
  let_it_be(:domain) { create(:pages_domain, project: project) }
  subject { described_class.new.perform(project.id) }

  it 'deletes published pages' do
    expect_any_instance_of(Gitlab::PagesTransfer).to receive(:rename_project).and_return true
    expect(PagesWorker).to receive(:perform_in).with(5.minutes, :remove, project.namespace.full_path, anything)

    subject

    expect(project.reload.pages_metadatum.deployed?).to be(false)
  end

  it 'deletes all domains' do
    expect(project.pages_domains.count).to be 1

    subject

    expect(project.reload.pages_domains.count).to be 0
  end
end
