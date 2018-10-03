# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Subquery do
  describe '.self_join' do
    set(:project) { create(:project) }

    it 'allows you to delete_all rows with WHERE and LIMIT' do
      events = create_list(:event, 8, project: project)

      expect do
        described_class.self_join(Event.where('id < ?', events[5]).recent.limit(2)).delete_all
      end.to change { Event.count }.by(-2)
    end
  end
end
