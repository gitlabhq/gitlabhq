# frozen_string_literal: true

RSpec.shared_examples 'model with wiki' do
  describe '#create_wiki' do
    it 'returns true if the wiki repository already exists' do
      expect(container.wiki_repository_exists?).to be(true)
      expect(container.create_wiki).to be(true)
    end

    it 'returns true if the wiki repository was created' do
      expect(container_without_wiki.wiki_repository_exists?).to be(false)
      expect(container_without_wiki.create_wiki).to be(true)
      expect(container_without_wiki.wiki_repository_exists?).to be(true)
    end

    context 'when the repository cannot be created' do
      before do
        expect(container.wiki).to receive(:create_wiki_repository) { raise Wiki::CouldNotCreateWikiError }
      end

      it 'returns false and adds a validation error' do
        expect(container.create_wiki).to be(false)
        expect(container.errors[:base]).to contain_exactly('Failed to create wiki')
      end
    end
  end

  describe '#wiki_repository_exists?' do
    it 'returns true when the wiki repository exists' do
      expect(container.wiki_repository_exists?).to eq(true)
    end

    it 'returns false when the wiki repository does not exist' do
      expect(container_without_wiki.wiki_repository_exists?).to eq(false)
    end
  end

  describe 'wiki path conflict' do
    context 'when the new path has been used by the wiki of other Project' do
      it 'has an error on the name attribute' do
        create(:project, namespace: container.parent, path: 'existing')
        container.path = 'existing.wiki'

        expect(container).not_to be_valid
        expect(container.errors[:name].first).to eq(_('has already been taken'))
      end
    end

    context 'when the new wiki path has been used by the path of other Project' do
      it 'has an error on the name attribute' do
        create(:project, namespace: container.parent, path: 'existing.wiki')
        container.path = 'existing'

        expect(container).not_to be_valid
        expect(container.errors[:name].first).to eq(_('has already been taken'))
      end
    end

    context 'when the new path has been used by the wiki of other Group' do
      it 'has an error on the name attribute' do
        create(:group, parent: container.parent, path: 'existing')
        container.path = 'existing.wiki'

        expect(container).not_to be_valid
        expect(container.errors[:name].first).to eq(_('has already been taken'))
      end
    end

    context 'when the new wiki path has been used by the path of other Group' do
      it 'has an error on the name attribute' do
        create(:group, parent: container.parent, path: 'existing.wiki')
        container.path = 'existing'

        expect(container).not_to be_valid
        expect(container.errors[:name].first).to eq(_('has already been taken'))
      end
    end
  end
end
