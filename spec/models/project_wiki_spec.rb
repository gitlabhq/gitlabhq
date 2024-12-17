# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectWiki, feature_category: :wiki do
  it_behaves_like 'wiki model' do
    let(:wiki_container) { create(:project, :wiki_repo, namespace: user.namespace) }
    let(:wiki_container_without_repo) { create(:project, namespace: user.namespace) }
    let(:wiki_lfs_enabled) { true }

    it { is_expected.to delegate_method(:storage).to(:container) }
    it { is_expected.to delegate_method(:repository_storage).to(:container) }
    it { is_expected.to delegate_method(:hashed_storage?).to(:container) }

    describe '#disk_path' do
      it 'returns the repository storage path' do
        expect(subject.disk_path).to eq("#{subject.container.disk_path}.wiki")
      end
    end

    describe '#create_wiki_repository' do
      context 'when a project_wiki_repositories record does not exist' do
        let_it_be(:wiki_container) { create(:project) }

        it 'creates a new record' do
          expect { subject.create_wiki_repository }.to change { wiki_container.wiki_repository }
            .from(nil).to(kind_of(Projects::WikiRepository))
        end

        context 'on a read-only instance' do
          before do
            allow(Gitlab::Database).to receive(:read_only?).and_return(true)
          end

          it 'does not attempt to create a new record' do
            expect { subject.create_wiki_repository }.not_to change { wiki_container.wiki_repository }
          end
        end
      end

      context 'when a project_wiki_repositories record exists' do
        it 'does not create a new record in the database' do
          expect { subject.create_wiki_repository }.not_to change { wiki_container.wiki_repository }
        end
      end
    end

    describe '#after_wiki_activity' do
      it 'updates project activity' do
        wiki_container.update!(
          last_activity_at: nil,
          last_repository_updated_at: nil
        )

        subject.send(:after_wiki_activity)
        wiki_container.reload

        expect(wiki_container.last_activity_at).to be_within(1.minute).of(Time.current)
        expect(wiki_container.last_repository_updated_at).to be_within(1.minute).of(Time.current)
      end
    end

    describe '#after_post_receive' do
      it 'updates project activity and expires caches' do
        expect(wiki).to receive(:after_wiki_activity)
        expect(ProjectCacheWorker).to receive(:perform_async).with(wiki_container.id, [], %w[wiki_size])

        subject.send(:after_post_receive)
      end
    end
  end

  it_behaves_like 'can housekeep repository' do
    let_it_be(:resource) { create(:project_wiki) }

    let(:resource_key) { 'project_wikis' }
    let(:expected_worker_class) { Wikis::GitGarbageCollectWorker }
  end
end
