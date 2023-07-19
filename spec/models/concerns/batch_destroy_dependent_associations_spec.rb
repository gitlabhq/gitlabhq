# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BatchDestroyDependentAssociations do
  class TestProject < ActiveRecord::Base
    self.table_name = 'projects'

    has_many :builds
    has_many :notification_settings, as: :source, dependent: :delete_all
    has_many :pages_domains
    has_many :todos, dependent: :destroy

    include BatchDestroyDependentAssociations
  end

  describe '#dependent_associations_to_destroy' do
    let_it_be(:project) { TestProject.new }

    it 'returns the right associations' do
      expect(project.dependent_associations_to_destroy.map(&:name)).to match_array([:todos])
    end
  end

  describe '#destroy_dependent_associations_in_batches' do
    let_it_be(:project) { create(:project) }
    let_it_be(:build) { create(:ci_build, project: project) }
    let_it_be(:notification_setting) { create(:notification_setting, project: project) }
    let_it_be(:note) { create(:note, project: project) }
    let_it_be(:merge_request) { create(:merge_request, :skip_diff_creation, source_project: project) }

    it 'destroys multiple notes' do
      create(:note, project: project)

      expect(Note.count).to eq(2)

      project.destroy_dependent_associations_in_batches

      expect(Note.count).to eq(0)
    end

    it 'destroys note in batches' do
      expect(project).to receive_message_chain(:notes, :find_each).and_yield(note)
      expect(note).to receive(:destroy).and_call_original

      project.destroy_dependent_associations_in_batches

      expect(Ci::Build.count).to eq(1)
      expect(Note.count).to eq(0)
      expect(User.count).to be > 0
      expect(NotificationSetting.count).to eq(User.count)
    end

    it 'excludes associations' do
      project.destroy_dependent_associations_in_batches(exclude: [:merge_requests])

      expect(MergeRequest.count).to eq(1)
      expect(Note.count).to eq(0)
      expect(Ci::Build.count).to eq(1)
      expect(User.count).to be > 0
      expect(NotificationSetting.count).to eq(User.count)
    end
  end
end
