# frozen_string_literal: true

require 'spec_helper'

describe GroupWiki do
  it_behaves_like 'wiki model' do
    let(:wiki_container) { create(:group, :wiki_repo) }
    let(:wiki_container_without_repo) { create(:group) }

    before do
      wiki_container.add_owner(user)
    end

    describe '#storage' do
      it 'uses the group repository prefix' do
        expect(subject.storage.base_dir).to start_with('@groups/')
      end
    end

    describe '#repository_storage' do
      it 'returns the default storage' do
        expect(subject.repository_storage).to eq('default')
      end
    end

    describe '#hashed_storage?' do
      it 'returns true' do
        expect(subject.hashed_storage?).to be(true)
      end
    end

    describe '#disk_path' do
      it 'returns the repository storage path' do
        expect(subject.disk_path).to eq("#{subject.storage.disk_path}.wiki")
      end
    end
  end
end
