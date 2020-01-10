# frozen_string_literal: true

require 'spec_helper'

describe Releases::UpdateService do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:new_name) { 'A new name' }
  let(:new_description) { 'The best release!' }
  let(:params) { { name: new_name, description: new_description, tag: tag_name } }
  let(:service) { described_class.new(project, user, params) }
  let!(:release) { create(:release, project: project, author: user, tag: tag_name) }
  let(:tag_name) { 'v1.1.0' }

  before do
    project.add_developer(user)
  end

  describe '#execute' do
    shared_examples 'a failed update' do
      it 'raises an error' do
        result = service.execute
        expect(result[:status]).to eq(:error)
        expect(result[:milestones_updated]).to be_falsy
      end
    end

    it 'successfully updates an existing release' do
      result = service.execute
      expect(result[:status]).to eq(:success)
      expect(result[:release].name).to eq(new_name)
      expect(result[:release].description).to eq(new_description)
    end

    context 'when the tag does not exists' do
      let(:tag_name) { 'foobar' }

      it_behaves_like 'a failed update'
    end

    context 'when the release does not exist' do
      let!(:release) { }

      it_behaves_like 'a failed update'
    end

    context 'with an invalid update' do
      let(:new_description) { '' }

      it_behaves_like 'a failed update'
    end

    context 'when a milestone is passed in' do
      let(:milestone) { create(:milestone, project: project, title: 'v1.0') }
      let(:params_with_milestone) { params.merge!({ milestones: [new_title] }) }
      let(:new_milestone) { create(:milestone, project: project, title: new_title) }
      let(:service) { described_class.new(new_milestone.project, user, params_with_milestone) }

      before do
        release.milestones << milestone
      end

      context 'a different milestone' do
        let(:new_title) { 'v2.0' }

        it 'updates the related milestone accordingly' do
          result = service.execute
          release.reload

          expect(release.milestones.first.title).to eq(new_title)
          expect(result[:milestones_updated]).to be_truthy
        end
      end

      context 'an identical milestone' do
        let(:new_title) { 'v1.0' }

        it "raises an error" do
          expect { service.execute }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context "when an 'empty' milestone is passed in" do
      let(:milestone) { create(:milestone, project: project, title: 'v1.0') }
      let(:params_with_empty_milestone) { params.merge!({ milestones: [] }) }

      before do
        release.milestones << milestone

        service.params = params_with_empty_milestone
      end

      it 'removes the old milestone and does not associate any new milestone' do
        result = service.execute
        release.reload

        expect(release.milestones).not_to be_present
        expect(result[:milestones_updated]).to be_truthy
      end
    end

    context "when multiple new milestones are passed in" do
      let(:new_title_1) { 'v2.0' }
      let(:new_title_2) { 'v2.0-rc' }
      let(:milestone) { create(:milestone, project: project, title: 'v1.0') }
      let(:params_with_milestones) { params.merge!({ milestones: [new_title_1, new_title_2] }) }
      let(:service) { described_class.new(project, user, params_with_milestones) }

      before do
        create(:milestone, project: project, title: new_title_1)
        create(:milestone, project: project, title: new_title_2)
        release.milestones << milestone
      end

      it 'removes the old milestone and update the release with the new ones' do
        result = service.execute
        release.reload

        milestone_titles = release.milestones.map(&:title)
        expect(milestone_titles).to match_array([new_title_1, new_title_2])
        expect(result[:milestones_updated]).to be_truthy
      end
    end
  end
end
