# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUserPreferencesEmojiAutocompleteDisabledMetric, feature_category: :service_ping do
  let(:expected_value) { 1 }

  before do
    create(:user).user_preference.update!(emoji_autocomplete_enabled: false)
    create(:user).user_preference.update!(emoji_autocomplete_enabled: true)
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
end
