# frozen_string_literal: true

require 'spec_helper'

describe ProjectWiki do
  it_behaves_like 'wiki model' do
    let(:wiki_container) { create(:project, :wiki_repo, namespace: user.namespace) }
    let(:wiki_container_without_repo) { create(:project, namespace: user.namespace) }

    it { is_expected.to delegate_method(:storage).to(:container) }
    it { is_expected.to delegate_method(:repository_storage).to(:container) }
    it { is_expected.to delegate_method(:hashed_storage?).to(:container) }

    describe '#disk_path' do
      it 'returns the repository storage path' do
        expect(subject.disk_path).to eq("#{subject.container.disk_path}.wiki")
      end
    end

    describe '#update_container_activity' do
      it 'updates project activity' do
        wiki_container.update!(
          last_activity_at: nil,
          last_repository_updated_at: nil
        )

        subject.create_page('Test Page', 'This is content')
        wiki_container.reload

        expect(wiki_container.last_activity_at).to be_within(1.minute).of(Time.current)
        expect(wiki_container.last_repository_updated_at).to be_within(1.minute).of(Time.current)
      end
    end
  end
end
