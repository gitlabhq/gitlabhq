# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvent, feature_category: :team_planning, type: :model do
  let(:dummy_resource_label_event_class) do
    Class.new(ResourceEvent) do
      self.table_name = 'resource_label_events'
    end
  end

  it 'raises error on not implemented `issuable` method' do
    expect { dummy_resource_label_event_class.new.issuable }.to raise_error(NoMethodError)
  end

  it 'raises error on not implemented `synthetic_note_class` method' do
    expect { dummy_resource_label_event_class.new.synthetic_note_class }.to raise_error(NoMethodError)
  end
end
