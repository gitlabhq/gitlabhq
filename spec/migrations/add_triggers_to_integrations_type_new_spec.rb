# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddTriggersToIntegrationsTypeNew do
  let(:migration) { described_class.new }
  let(:integrations) { table(:integrations) }

  describe '#up' do
    before do
      migrate!
    end

    describe 'INSERT trigger' do
      it 'sets `type_new` to the transformed `type` class name' do
        Gitlab::Integrations::StiType.namespaced_integrations.each do |type|
          integration = integrations.create!(type: "#{type}Service")

          expect(integration.reload).to have_attributes(
            type: "#{type}Service",
            type_new: "Integrations::#{type}"
          )
        end
      end

      it 'ignores types that are not namespaced' do
        # We don't actually have any integrations without namespaces,
        # but we can abuse one of the integration base classes.
        integration = integrations.create!(type: 'BaseIssueTracker')

        expect(integration.reload).to have_attributes(
          type: 'BaseIssueTracker',
          type_new: nil
        )
      end

      it 'ignores types that are unknown' do
        integration = integrations.create!(type: 'FooBar')

        expect(integration.reload).to have_attributes(
          type: 'FooBar',
          type_new: nil
        )
      end
    end
  end

  describe '#down' do
    before do
      migration.up
      migration.down
    end

    it 'drops the INSERT trigger' do
      integration = integrations.create!(type: 'JiraService')

      expect(integration.reload).to have_attributes(
        type: 'JiraService',
        type_new: nil
      )
    end
  end
end
