# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::Orphans::RepositoryCheck, :silence_stdout do
  let(:storages) { Gitlab.config.repositories.storages.reject { |key, _| key.eql? 'broken' } }

  before do
    allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    allow(subject).to receive(:fetch_disk_namespaces).and_return(disk_namespaces)
    allow(subject).to receive(:fetch_disk_repositories).and_return(disk_repositories)
  end

  describe '#multi_check' do
    context 'all orphans' do
      let(:disk_namespaces) { %w(/repos/orphan1 /repos/orphan2 repos/@hashed) }
      let(:disk_repositories) { %w(repo1.git repo2.git) }

      it 'prints list of all orphaned namespaces except @hashed' do
        expect_list_of_orphans(%w(orphan1/repo1.git orphan1/repo2.git orphan2/repo1.git orphan2/repo2.git))

        subject.multi_check
      end
    end

    context 'few orphans with existing namespace' do
      let!(:first_level) { create(:group, path: 'my-namespace') }
      let!(:project) { create(:project, path: 'repo', namespace: first_level) }
      let(:disk_namespaces) { %w(/repos/orphan1 /repos/orphan2 /repos/my-namespace /repos/@hashed) }
      let(:disk_repositories) { %w(repo.git) }

      it 'prints list of orphaned namespaces' do
        expect_list_of_orphans(%w(orphan1/repo.git orphan2/repo.git))

        subject.multi_check
      end
    end

    context 'few orphans with existing namespace and parents with same name as orphans' do
      let!(:first_level) { create(:group, path: 'my-namespace') }
      let!(:second_level) { create(:group, path: 'second-level', parent: first_level) }
      let!(:project) { create(:project, path: 'repo', namespace: first_level) }
      let(:disk_namespaces) { %w(/repos/orphan1 /repos/orphan2 /repos/my-namespace /repos/second-level /repos/@hashed) }
      let(:disk_repositories) { %w(repo.git) }

      it 'prints list of orphaned namespaces ignoring parents with same namespace as orphans' do
        expect_list_of_orphans(%w(orphan1/repo.git orphan2/repo.git second-level/repo.git))

        subject.multi_check
      end
    end

    context 'no orphans' do
      let(:disk_namespaces) { %w(@hashed) }
      let(:disk_repositories) { %w(repo.git) }

      it 'prints an empty list ignoring @hashed' do
        expect_list_of_orphans([])

        subject.multi_check
      end
    end
  end

  def expect_list_of_orphans(orphans)
    expect(subject).to receive(:print_orphans).with(orphans, 'default')
  end
end
