# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::ApplicationSetting do
  let_it_be(:application_setting, reload: true) { create(:application_setting) }

  subject(:output) { described_class.new(application_setting).as_json }

  context 'housekeeping_bitmaps_enabled usage is deprecated and always enabled' do
    before do
      application_setting.housekeeping_bitmaps_enabled = housekeeping_bitmaps_enabled
    end

    context 'when housekeeping_bitmaps_enabled db column is false' do
      let(:housekeeping_bitmaps_enabled) { false }

      it 'returns true' do
        expect(subject[:housekeeping_bitmaps_enabled]).to eq(true)
      end
    end

    context 'when housekeeping_bitmaps_enabled db column is true' do
      let(:housekeeping_bitmaps_enabled) { false }

      it 'returns true' do
        expect(subject[:housekeeping_bitmaps_enabled]).to eq(true)
      end
    end
  end
end
