# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPages::BaseService do
  let(:project) { double('project') }
  let(:user) { double('user') }

  describe '#increment_usage' do
    counter = Gitlab::UsageDataCounters::WikiPageCounter
    error = counter::UnknownEvent

    let(:subject) { bad_service_class.new(container: project, current_user: user) }

    context 'the class implements usage_counter_action incorrectly' do
      let(:bad_service_class) do
        Class.new(described_class) do
          def usage_counter_action
            :bad_event
          end
        end
      end

      it 'raises an error on unknown events' do
        expect { subject.send(:increment_usage) }.to raise_error(error)
      end
    end
  end
end
