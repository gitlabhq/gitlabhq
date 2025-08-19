# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DetailedStatusEntity do
  let(:entity) { described_class.new(status) }
  let(:status) do
    Gitlab::Ci::Status::Success.new(double('object'), double('user'))
  end

  before do
    allow(status).to receive(:has_details?).and_return(true)
    allow(status).to receive(:details_path).and_return('some/path')
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains status details' do
      expect(subject).to include :text, :icon, :favicon, :label, :group, :tooltip
      expect(subject).to include :has_details, :details_path
      expect(subject[:favicon]).to match_asset_path('/assets/ci_favicons/favicon_status_success.png')
    end

    describe '.action' do
      let_it_be(:ci_stage) { create(:ci_stage, status: :skipped) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- We need ID for path generation
      let(:status) do
        Gitlab::Ci::Status::Stage::Factory.new(ci_stage, nil).fabricate!
      end

      it 'returns action details' do
        expect(subject).to include :text, :icon
        expect(subject[:action]).to include :icon, :title, :path, :method, :button_title, :confirmation_message
      end

      context 'when parameter disable_stage_actions is passed in' do
        let(:entity) { described_class.new(status, disable_stage_actions: true) }

        it 'does not return action details' do
          expect(subject).to include :text, :icon
          expect(subject).not_to include :action
        end

        context 'and status is not Ci::Stage' do
          let_it_be(:build) { create(:ci_build, :manual) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- We need ID for path generation
          let(:status) do
            Gitlab::Ci::Status::Build::Factory.new(build, nil).fabricate!
          end

          before do
            allow(status).to receive(:has_action?).and_return(true)
          end

          it 'returns action details' do
            expect(subject).to include :text, :icon
            expect(subject[:action]).to include :icon, :title, :path, :method, :button_title, :confirmation_message
          end
        end
      end
    end
  end
end
