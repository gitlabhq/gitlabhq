# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeleteService do
  shared_examples 'remove pages' do
    let_it_be(:project) { create(:project, path: "my.project")}
    let_it_be(:admin) { create(:admin) }
    let_it_be(:domain) { create(:pages_domain, project: project) }
    let_it_be(:service) { described_class.new(project, admin)}

    it 'deletes published pages' do
      expect_any_instance_of(Gitlab::PagesTransfer).to receive(:rename_project).and_return true
      expect(PagesWorker).to receive(:perform_in).with(5.minutes, :remove, project.namespace.full_path, anything)

      Sidekiq::Testing.inline! { service.execute }

      expect(project.reload.pages_metadatum.deployed?).to be(false)
    end

    it 'deletes all domains' do
      expect(project.pages_domains.count).to be 1

      Sidekiq::Testing.inline! { service.execute }

      expect(project.reload.pages_domains.count).to be 0
    end
  end

  context 'with feature flag enabled' do
    before do
      expect(PagesRemoveWorker).to receive(:perform_async).and_call_original
    end

    it_behaves_like 'remove pages'
  end
end
