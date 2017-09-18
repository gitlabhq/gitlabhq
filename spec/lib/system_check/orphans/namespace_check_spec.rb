require 'spec_helper'
require 'rake_helper'

describe SystemCheck::Orphans::NamespaceCheck do
  let(:storages) { Gitlab.config.repositories.storages.reject { |key, _| key.eql? 'broken' } }

  before do
    allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    allow(subject).to receive(:fetch_disk_namespaces).and_return(disk_namespaces)
    silence_output
  end

  describe '#multi_check' do
    context 'all orphans' do
      let(:disk_namespaces) { %w(/repos/orphan1 /repos/orphan2 repos/@hashed) }

      it 'prints list of all orphaned namespaces except @hashed' do
        expect_list_of_orphans(%w(orphan1 orphan2))

        subject.multi_check
      end
    end

    context 'few orphans with existing namespace' do
      let!(:first_level) { create(:group, path: 'my-namespace') }
      let(:disk_namespaces) { %w(/repos/orphan1 /repos/orphan2 /repos/my-namespace /repos/@hashed) }

      it 'prints list of orphaned namespaces' do
        expect_list_of_orphans(%w(orphan1 orphan2))

        subject.multi_check
      end
    end

    context 'few orphans with existing namespace and parents with same name as orphans' do
      let!(:first_level) { create(:group, path: 'my-namespace') }
      let!(:second_level) { create(:group, path: 'second-level', parent: first_level) }
      let(:disk_namespaces) { %w(/repos/orphan1 /repos/orphan2 /repos/my-namespace /repos/second-level /repos/@hashed) }

      it 'prints list of orphaned namespaces ignoring parents with same namespace as orphans' do
        expect_list_of_orphans(%w(orphan1 orphan2 second-level))

        subject.multi_check
      end
    end

    context 'no orphans' do
      let(:disk_namespaces) { %w(@hashed) }

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
