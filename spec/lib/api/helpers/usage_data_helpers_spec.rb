# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::UsageDataHelpers, feature_category: :service_ping do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  describe '#process_event' do
    let(:helper) { Class.new.include(described_class).new }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:track_event)
      allow(::ProjectsFinder).to receive(:new).and_call_original
    end

    def expect_tracked(namespace_id:, project_id:, send_snowplow_event: false, additional_properties: {})
      expect(helper).to have_received(:track_event).with(
        'an_event',
        send_snowplow_event: send_snowplow_event,
        user: user,
        namespace_id: namespace_id,
        project_id: project_id,
        additional_properties: additional_properties
      )
    end

    it 'tracks the event with the ids it was given' do
      helper.process_event({ event: 'an_event', namespace_id: 1, project_id: 2 })

      expect_tracked(namespace_id: 1, project_id: 2)
      expect(::ProjectsFinder).not_to have_received(:new)
    end

    it 'symbolizes the additional properties' do
      helper.process_event({ event: 'an_event', additional_properties: { 'label' => 'x', 'value' => 1 } })

      expect_tracked(namespace_id: nil, project_id: nil, additional_properties: { label: 'x', value: 1 })
    end

    it 'casts send_to_snowplow to a boolean' do
      helper.process_event({ event: 'an_event', send_to_snowplow: true })

      expect_tracked(namespace_id: nil, project_id: nil, send_snowplow_event: true)
    end

    context 'with a project_path' do
      it 'resolves the project and its namespace' do
        helper.process_event({ event: 'an_event', project_path: project.full_path })

        expect_tracked(namespace_id: project.namespace_id, project_id: project.id)
        expect(::ProjectsFinder).to have_received(:new)
      end

      it 'reuses an already resolved project instead of querying again' do
        helper.process_event({ event: 'an_event', project_path: project.full_path },
          { project.full_path => project })

        expect_tracked(namespace_id: project.namespace_id, project_id: project.id)
        expect(::ProjectsFinder).not_to have_received(:new)
      end

      it 'keeps a namespace_id that was given explicitly' do
        helper.process_event({ event: 'an_event', namespace_id: 99, project_path: project.full_path },
          { project.full_path => project })

        expect_tracked(namespace_id: 99, project_id: project.id)
      end

      it 'tracks without a project when the path resolves to nothing' do
        helper.process_event({ event: 'an_event', project_path: 'no-such-group/no-such-project' })

        expect_tracked(namespace_id: nil, project_id: nil)
      end
    end
  end
end
