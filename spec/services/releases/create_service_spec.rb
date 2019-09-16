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
        inexistent_milestone_tag = 'v111.0'
        service = described_class.new(project, user, params.merge!({ milestones: [inexistent_milestone_tag] }))
        result = service.execute

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Milestone(s) not found: #{inexistent_milestone_tag}")
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
      let(:params_with_milestone) { params.merge!({ milestones: [title] }) }
      let(:service) { described_class.new(milestone.project, user, params_with_milestone) }

      it 'creates a release and ties this milestone to it' do
        result = service.execute

        expect(project.releases.count).to eq(1)
        expect(result[:status]).to eq(:success)

        release = project.releases.last

        expect(release.milestones).to match_array([milestone])
      end

      context 'when another release was previously created with that same milestone linked' do
        it 'also creates another release tied to that same milestone' do
          other_release = create(:release, milestones: [milestone], project: project, tag: 'v1.0')
          service.execute
          release = project.releases.last

          expect(release.milestones).to match_array([milestone])
          expect(other_release.milestones).to match_array([milestone])
          expect(release.id).not_to eq(other_release.id)
        end
      end
    end

    context 'when multiple existing milestone titles are passed in' do
      let(:title_1) { 'v1.0' }
      let(:title_2) { 'v1.0-rc' }
      let!(:milestone_1) { create(:milestone, :active, project: project, title: title_1) }
      let!(:milestone_2) { create(:milestone, :active, project: project, title: title_2) }
      let!(:params_with_milestones) { params.merge!({ milestones: [title_1, title_2] }) }

      it 'creates a release and ties it to these milestones' do
        described_class.new(project, user, params_with_milestones).execute
        release = project.releases.last

        expect(release.milestones.map(&:title)).to include(title_1, title_2)
      end
    end

    context 'when multiple miletone titles are passed in but one of them does not exist' do
      let(:title) { 'v1.0' }
      let(:inexistent_title) { 'v111.0' }
      let!(:milestone) { create(:milestone, :active, project: project, title: title) }
      let!(:params_with_milestones) { params.merge!({ milestones: [title, inexistent_title] }) }
      let(:service) { described_class.new(milestone.project, user, params_with_milestones) }

      it 'raises an error' do
        result = service.execute

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Milestone(s) not found: #{inexistent_title}")
      end

      it 'does not create any release' do
        expect do
          service.execute
        end.not_to change(Release, :count)
      end
    end

    context 'when no milestone is passed in' do
      it 'creates a release without a milestone tied to it' do
        expect(params.key? :milestones).to be_falsey

        service.execute
        release = project.releases.last

        expect(release.milestones).to be_empty
      end

      it 'does not create any new MilestoneRelease object' do
        expect { service.execute }.not_to change { MilestoneRelease.count }
      end
    end

    context 'when an empty value is passed as a milestone' do
      it 'creates a release without a milestone tied to it' do
        service = described_class.new(project, user, params.merge!({ milestones: [] }))
        service.execute
        release = project.releases.last

        expect(release.milestones).to be_empty
      end
    end
  end
end
