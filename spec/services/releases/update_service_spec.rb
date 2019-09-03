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
      let(:old_title) { 'v1.0' }
      let(:new_title) { 'v2.0' }
      let(:milestone) { create(:milestone, project: project, title: old_title) }
      let(:new_milestone) { create(:milestone, project: project, title: new_title) }
      let(:params_with_milestone) { params.merge!({ milestone: new_title }) }

      before do
        release.milestone = milestone
        release.save!

        described_class.new(new_milestone.project, user, params_with_milestone).execute
        release.reload
      end

      it 'updates the related milestone accordingly' do
        expect(release.milestone.title).to eq(new_title)
      end
    end

    context "when an 'empty' milestone is passed in" do
      let(:milestone) { create(:milestone, project: project, title: 'v1.0') }
      let(:params_with_empty_milestone) { params.merge!({ milestone: '' }) }

      before do
        release.milestone = milestone
        release.save!

        described_class.new(milestone.project, user, params_with_empty_milestone).execute
        release.reload
      end

      it 'removes the old milestone and does not associate any new milestone' do
        expect(release.milestone).to be_nil
      end
    end
  end
end
