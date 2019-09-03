# frozen_string_literal: true

require 'spec_helper'

describe Releases::CreateService do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:tag_name) { project.repository.tag_names.first }
  let(:tag_sha) { project.repository.find_tag(tag_name).dereferenced_target.sha }
  let(:name) { 'Bionic Beaver' }
  let(:description) { 'Awesome release!' }
  let(:params) { { tag: tag_name, name: name, description: description, ref: ref } }
  let(:ref) { nil }
  let(:service) { described_class.new(project, user, params) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    shared_examples 'a successful release creation' do
      it 'creates a new release' do
        result = service.execute

        expect(project.releases.count).to eq(1)
        expect(result[:status]).to eq(:success)
        expect(result[:tag]).not_to be_nil
        expect(result[:release]).not_to be_nil
        expect(result[:release].description).to eq(description)
        expect(result[:release].name).to eq(name)
        expect(result[:release].author).to eq(user)
        expect(result[:release].sha).to eq(tag_sha)
      end
    end

    it_behaves_like 'a successful release creation'

    context 'when the tag does not exist' do
      let(:tag_name) { 'non-exist-tag' }

      it 'raises an error' do
        result = service.execute

        expect(result[:status]).to eq(:error)
      end
    end

    context 'when ref is provided' do
      let(:ref) { 'master' }
      let(:tag_name) { 'foobar' }

      it_behaves_like 'a successful release creation'

      it 'creates a tag if the tag does not exist' do
        expect(project.repository.ref_exists?("refs/tags/#{tag_name}")).to be_falsey

        result = service.execute
        expect(result[:status]).to eq(:success)
        expect(result[:tag]).not_to be_nil
        expect(result[:release]).not_to be_nil
      end
    end

    context 'there already exists a release on a tag' do
      let!(:release) do
        create(:release, project: project, tag: tag_name, description: description)
      end

      it 'raises an error and does not update the release' do
        result = service.execute
        expect(result[:status]).to eq(:error)
        expect(project.releases.find_by(tag: tag_name).description).to eq(description)
      end
    end

    context 'when a passed-in milestone does not exist for this project' do
      it 'raises an error saying the milestone is inexistent' do
        service = described_class.new(project, user, params.merge!({ milestone: 'v111.0' }))
        result = service.execute
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Milestone does not exist')
      end
    end
  end

  describe '#find_or_build_release' do
    it 'does not save the built release' do
      service.find_or_build_release

      expect(project.releases.count).to eq(0)
    end

    context 'when existing milestone is passed in' do
      let(:title) { 'v1.0' }
      let(:milestone) { create(:milestone, :active, project: project, title: title) }
      let(:params_with_milestone) { params.merge!({ milestone: title }) }

      it 'creates a release and ties this milestone to it' do
        service = described_class.new(milestone.project, user, params_with_milestone)
        result = service.execute

        expect(project.releases.count).to eq(1)
        expect(result[:status]).to eq(:success)

        release = project.releases.last

        expect(release.milestone).to eq(milestone)
      end

      context 'when another release was previously created with that same milestone linked' do
        it 'also creates another release tied to that same milestone' do
          other_release = create(:release, milestone: milestone, project: project, tag: 'v1.0')
          service = described_class.new(milestone.project, user, params_with_milestone)
          service.execute
          release = project.releases.last

          expect(release.milestone).to eq(milestone)
          expect(other_release.milestone).to eq(milestone)
          expect(release.id).not_to eq(other_release.id)
        end
      end
    end

    context 'when no milestone is passed in' do
      it 'creates a release without a milestone tied to it' do
        expect(params.key? :milestone).to be_falsey
        service.execute
        release = project.releases.last
        expect(release.milestone).to be_nil
      end

      it 'does not create any new MilestoneRelease object' do
        expect { service.execute }.not_to change { MilestoneRelease.count }
      end
    end

    context 'when an empty value is passed as a milestone' do
      it 'creates a release without a milestone tied to it' do
        service = described_class.new(project, user, params.merge!({ milestone: '' }))
        service.execute
        release = project.releases.last
        expect(release.milestone).to be_nil
      end
    end
  end
end
