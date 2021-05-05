# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Release do
  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:release) { create(:release, project: project, author: user) }

  it { expect(release).to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:project).touch(true) }
    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to have_many(:links).class_name('Releases::Link') }
    it { is_expected.to have_many(:milestones) }
    it { is_expected.to have_many(:milestone_releases) }
    it { is_expected.to have_many(:evidences).class_name('Releases::Evidence') }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:tag) }

    context 'when a release exists in the database without a name' do
      it 'does not require name' do
        existing_release_without_name = build(:release, project: project, author: user, name: nil)
        existing_release_without_name.save(validate: false)

        existing_release_without_name.description = "change"
        existing_release_without_name.save
        existing_release_without_name.reload

        expect(existing_release_without_name).to be_valid
        expect(existing_release_without_name.description).to eq("change")
        expect(existing_release_without_name.name).not_to be_nil
      end
    end

    context 'when description of a release is longer than the limit' do
      let(:description) { 'a' * (Gitlab::Database::MAX_TEXT_SIZE_LIMIT + 1) }
      let(:release) { build(:release, project: project, description: description) }

      it 'creates a validation error' do
        release.validate

        expect(release.errors.full_messages)
          .to include("Description is too long (maximum is #{Gitlab::Database::MAX_TEXT_SIZE_LIMIT} characters)")
      end
    end

    context 'when a release is tied to a milestone for another project' do
      it 'creates a validation error' do
        milestone = build(:milestone, project: create(:project))
        expect { release.milestones << milestone }.to raise_error
      end
    end

    context 'when a release is tied to a milestone linked to the same project' do
      it 'successfully links this release to this milestone' do
        milestone = build(:milestone, project: project)
        expect { release.milestones << milestone }.to change { MilestoneRelease.count }.by(1)
      end
    end
  end

  describe '#assets_count' do
    subject { Release.find(release.id).assets_count }

    it 'returns the number of sources' do
      is_expected.to eq(Gitlab::Workhorse::ARCHIVE_FORMATS.count)
    end

    context 'when a links exists' do
      let!(:link) { create(:release_link, release: release) }

      it 'counts the link as an asset' do
        is_expected.to eq(1 + Gitlab::Workhorse::ARCHIVE_FORMATS.count)
      end

      it "excludes sources count when asked" do
        assets_count = Release.find(release.id).assets_count(except: [:sources])
        expect(assets_count).to eq(1)
      end
    end
  end

  describe '.create' do
    it "fills released_at using created_at if it's not set" do
      release = described_class.create(project: project, author: user)

      expect(release.released_at).to eq(release.created_at)
    end

    it "does not change released_at if it's set explicitly" do
      released_at = Time.zone.parse('2018-10-20T18:00:00Z')

      release = described_class.create(project: project, author: user, released_at: released_at)

      expect(release.released_at).to eq(released_at)
    end
  end

  describe '#update' do
    subject { release.update(params) }

    context 'when links do not exist' do
      context 'when params are specified for creation' do
        let(:params) do
          { links_attributes: [{ name: 'test', url: 'https://www.google.com/' }] }
        end

        it 'creates a link successfuly' do
          is_expected.to eq(true)

          expect(release.links.count).to eq(1)
          expect(release.links.first.name).to eq('test')
          expect(release.links.first.url).to eq('https://www.google.com/')
        end
      end
    end

    context 'when a link exists' do
      let!(:link1) { create(:release_link, release: release, name: 'test1', url: 'https://www.google1.com/') }
      let!(:link2) { create(:release_link, release: release, name: 'test2', url: 'https://www.google2.com/') }

      before do
        release.reload
      end

      context 'when params are specified for update' do
        let(:params) do
          { links_attributes: [{ id: link1.id, name: 'new' }] }
        end

        it 'updates the link successfully' do
          is_expected.to eq(true)

          expect(release.links.count).to eq(2)
          expect(release.links.first.name).to eq('new')
        end
      end

      context 'when params are specified for deletion' do
        let(:params) do
          { links_attributes: [{ id: link1.id, _destroy: true }] }
        end

        it 'removes the link successfuly' do
          is_expected.to eq(true)

          expect(release.links.count).to eq(1)
          expect(release.links.first.name).to eq(link2.name)
        end
      end
    end
  end

  describe '#sources' do
    subject { release.sources }

    it 'returns sources' do
      is_expected.to all(be_a(Releases::Source))
    end
  end

  describe '#upcoming_release?' do
    context 'during the backfill migration when released_at could be nil' do
      it 'handles a nil released_at value and returns false' do
        allow(release).to receive(:released_at).and_return nil

        expect(release.upcoming_release?).to eq(false)
      end
    end
  end

  describe 'evidence' do
    let(:release_with_evidence) { create(:release, :with_evidence, project: project) }

    context 'when a release is deleted' do
      it 'also deletes the associated evidence' do
        release_with_evidence

        expect { release_with_evidence.destroy }.to change(Releases::Evidence, :count).by(-1)
      end
    end
  end

  describe '#name' do
    context 'name is nil' do
      before do
        release.update(name: nil)
      end

      it 'returns tag' do
        expect(release.name).to eq(release.tag)
      end
    end
  end

  describe '#milestone_titles' do
    let_it_be(:milestone_1) { create(:milestone, project: project, title: 'Milestone 1') }
    let_it_be(:milestone_2) { create(:milestone, project: project, title: 'Milestone 2') }
    let_it_be(:release) { create(:release, project: project, milestones: [milestone_1, milestone_2]) }

    it { expect(release.milestone_titles).to eq("#{milestone_1.title}, #{milestone_2.title}")}
  end
end
