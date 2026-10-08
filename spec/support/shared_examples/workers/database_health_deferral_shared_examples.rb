# frozen_string_literal: true

RSpec.shared_examples 'defers on database health signal behind a feature flag' do
  |feature_flag:, gitlab_schema:, delay_by:, indicators:|
  it 'watches the given indicators on the given database' do
    expect(described_class.database_health_check_attrs).to include(
      gitlab_schema: gitlab_schema,
      delay_by: delay_by,
      indicators: indicators
    )
  end

  it 'defers when the feature flag is enabled' do
    expect(described_class.defer_on_database_health_signal?).to be(true)
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(feature_flag => false)
    end

    it 'does not defer' do
      expect(described_class.defer_on_database_health_signal?).to be(false)
    end
  end
end
