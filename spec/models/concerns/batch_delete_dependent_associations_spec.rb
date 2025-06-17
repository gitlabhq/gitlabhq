# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BatchDeleteDependentAssociations, feature_category: :shared do
  let(:test_project_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'projects'

      has_many :builds
      has_many :notification_settings, as: :source, dependent: :delete_all
      has_many :pages_domains
      has_many :todos, dependent: :delete_all
      has_many :issues, dependent: :destroy

      include BatchDeleteDependentAssociations
    end
  end

  describe '#dependent_associations_to_destroy' do
    let(:project) { test_project_class.new }

    it 'returns the right associations' do
      expect(project.dependent_associations_to_delete.map(&:name)).to match_array([:notification_settings, :todos])
    end
  end

  describe '#delete_dependent_associations_in_batches' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, creator: user) }
    let_it_be(:events) { create_list(:event, 4, author: user, project: project) }
    let_it_be(:todos) { create_list(:todo, 4, user: user) }
    let_it_be(:note) { create(:note, author: user, project: project) }
    let_it_be(:issue) { create(:issue, author: user, project: project) }

    it 'deletes all notification_settings' do
      expect(Event.count).to eq(4)
      expect(Todo.count).to eq(4)

      user.delete_dependent_associations_in_batches

      expect(Event.count).to eq(0)
      expect(Todo.count).to eq(0)
    end

    it 'deletes note in batches' do
      expect(user).to receive(:events).exactly(3).times.and_call_original

      user.delete_dependent_associations_in_batches(batch_size: 2)

      expect(Issue.find(issue.id)).to be_present
      expect(Note.count).to eq(1)
      expect(Event.count).to eq(0)
      expect(Todo.count).to eq(0)
    end

    it 'excludes associations' do
      user.delete_dependent_associations_in_batches(exclude: [:todos])

      expect(Event.count).to eq(0)
      expect(Todo.count).to eq(4)
    end
  end
end
