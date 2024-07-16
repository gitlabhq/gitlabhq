# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvent, feature_category: :team_planning, type: :model do
  context 'when inheriting from ResourceEvent' do
    context 'when it does not implement the #issuable method' do
      let(:dummy_resource_label_event_class) do
        Class.new(ResourceEvent) do
          self.table_name = 'resource_label_events'

          def self.name
            'DummyResourceLabelEventClass'
          end
        end
      end

      it 'raises error on not implemented `issuable` method' do
        expect { dummy_resource_label_event_class.new.issuable }
          .to raise_error(
            NoMethodError,
            "`DummyResourceLabelEventClass#issuable` method must be implemented"
          )
      end
    end

    context 'when it does not implement the #synthetic_note_class method' do
      let(:dummy_resource_label_event_class) do
        Class.new(ResourceEvent) do
          self.table_name = 'resource_label_events'

          def self.name
            'DummyResourceLabelEventClass'
          end

          def issuable
            :issuable
          end
        end
      end

      it 'raises error on not implemented `issuable` method' do
        expect { dummy_resource_label_event_class.new.synthetic_note_class }
          .to raise_error(NoMethodError, <<~MESSAGE.squish)
            `DummyResourceLabelEventClass#synthetic_note_class` method must be implemented
            (return nil if event does not require a note)
          MESSAGE
      end
    end

    it 'must implement #synthetic_note_class method', :aggregate_failures do
      Dir['{ee/,}app/models/**/resource*event.rb'].each do |klass|
        require(Rails.root.join(klass))
      end

      described_class.subclasses.each do |klass|
        next if klass.abstract_class?

        expect { klass.new.synthetic_note_class }
          .not_to(raise_error)
      end
    end
  end
end
