# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::BaseThirdPartyWiki do
  describe 'default values' do
    it { expect(subject.category).to eq(:third_party_wiki) }
  end

  describe 'Validations' do
    let_it_be_with_reload(:project) { create(:project) }

    describe 'only one third party wiki per project' do
      subject(:integration) { create(:shimo_integration, project: project, active: true) }

      before_all do
        create(:confluence_integration, project: project, active: true)
      end

      context 'when integration is changed manually by user' do
        it 'executes the validation' do
          valid = integration.valid?(:manual_change)

          expect(valid).to be_falsey
          error_message = 'Another third-party wiki is already in use. '\
                          'Only one third-party wiki integration can be active at a time'
          expect(integration.errors[:base]).to include _(error_message)
        end
      end

      context 'when integration is changed internally' do
        it 'does not execute the validation' do
          expect(integration.valid?).to be_truthy
        end
      end

      context 'when integration is not on the project level' do
        subject(:integration) { create(:shimo_integration, :instance, active: true) }

        it 'executes the validation' do
          expect(integration.valid?(:manual_change)).to be_truthy
        end
      end
    end
  end
end
