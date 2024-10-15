# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPages::BaseService, feature_category: :wiki do
  let(:project) { double('project') }
  let(:user) { double('user') }
  let(:page) { instance_double(WikiPage, template?: false) }

  before do
    allow(page).to receive(:[]).with(:format).and_return('markdown')
  end

  describe '#increment_usage' do
    let(:subject) { bad_service_class.new(container: project, current_user: user) }

    context 'the class implements internal_event_name incorrectly' do
      let(:bad_service_class) do
        Class.new(described_class) do
          def internal_event_name
            :bad_event
          end
        end
      end

      it 'raises an error on unknown events' do
        expect do
          subject.send(:increment_usage, page)
        end.to raise_error(Gitlab::Tracking::EventValidator::UnknownEventError)
      end
    end
  end
end
