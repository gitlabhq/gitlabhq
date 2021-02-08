# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesRemoveWorker do
  let(:project) { create(:project, path: "my.project")}
  let!(:domain) { create(:pages_domain, project: project) }

  subject { described_class.new.perform(project.id) }

  before do
    project.mark_pages_as_deployed
  end

  it 'deletes published pages' do
    expect(project.pages_deployed?).to be(true)

    expect_any_instance_of(Gitlab::PagesTransfer).to receive(:rename_project).and_return true
    expect(PagesWorker).to receive(:perform_in).with(5.minutes, :remove, project.namespace.full_path, anything)

    subject

    expect(project.reload.pages_deployed?).to be(false)
  end
end
