require 'spec_helper'

describe Geo::RepositoryUpdatedEventStore do
  let(:project)  { create(:project) }
  let(:blankrev) { Gitlab::Git::BLANK_SHA }
  let(:refs)     { ['refs/heads/tést', 'refs/tags/tag'] }

  let(:changes) do
    [
      { before: '123456', after: '789012', ref: 'refs/heads/tést' },
      { before: '654321', after: '210987', ref: 'refs/tags/tag' }
    ]
  end

  describe '#create' do
    it 'does not create a push event when not running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      subject = described_class.new(project, refs: refs, changes: changes)

      expect { subject.create }.not_to change(Geo::RepositoryUpdatedEvent, :count)
    end

    context 'when running on a primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'creates a push event' do
        subject = described_class.new(project, refs: refs, changes: changes)

        expect { subject.create }.to change(Geo::RepositoryUpdatedEvent, :count).by(1)
      end

      context 'when repository is being updated' do
        it 'does not track ref name when post-receive event affect multiple refs' do
          subject = described_class.new(project, refs: refs, changes: changes)

          subject.create

          expect(Geo::RepositoryUpdatedEvent.last.ref).to be_nil
        end

        it 'tracks ref name when post-receive event affect single ref' do
          refs    = ['refs/heads/tést']
          changes = [{ before: '123456', after: blankrev, ref: 'refs/heads/tést' }]
          subject = described_class.new(project, refs: refs, changes: changes)

          subject.create

          expect(Geo::RepositoryUpdatedEvent.last.ref).to eq 'refs/heads/tést'
        end

        it 'tracks number of branches post-receive event affects' do
          subject = described_class.new(project, refs: refs, changes: changes)

          subject.create

          expect(Geo::RepositoryUpdatedEvent.last.branches_affected).to eq 1
        end

        it 'tracks number of tags post-receive event affects' do
          subject = described_class.new(project, refs: refs, changes: changes)

          subject.create

          expect(Geo::RepositoryUpdatedEvent.last.tags_affected).to eq 1
        end

        it 'tracks when post-receive event create new branches' do
          refs    = ['refs/heads/tést', 'refs/heads/feature']
          changes = [
            { before: '123456', after: '789012', ref: 'refs/heads/tést' },
            { before: blankrev, after: '210987', ref: 'refs/heads/feature' }
          ]

          subject = described_class.new(project, refs: refs, changes: changes)

          subject.create

          expect(Geo::RepositoryUpdatedEvent.last.new_branch).to eq true
        end

        it 'tracks when post-receive event remove branches' do
          refs    = ['refs/heads/tést', 'refs/heads/feature']
          changes = [
            { before: '123456', after: '789012', ref: 'refs/heads/tést' },
            { before: '654321', after: blankrev, ref: 'refs/heads/feature' }
          ]
          subject = described_class.new(project, refs: refs, changes: changes)

          subject.create

          expect(Geo::RepositoryUpdatedEvent.last.remove_branch).to eq true
        end
      end

      context 'when wiki is being updated' do
        it 'does not track any information' do
          subject = described_class.new(project, source: Geo::RepositoryUpdatedEvent::WIKI)

          subject.create

          push_event = Geo::RepositoryUpdatedEvent.last

          expect(push_event.ref).to be_nil
          expect(push_event.branches_affected).to be_zero
          expect(push_event.tags_affected).to be_zero
          expect(push_event.new_branch).to eq false
          expect(push_event.remove_branch).to eq false
        end
      end
    end
  end
end
