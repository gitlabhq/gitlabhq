# frozen_string_literal: true

RSpec.shared_examples 'measurable service' do
  context 'when measurement is enabled' do
    let!(:measuring) { Gitlab::Utils::Measuring.new(base_log_data) }

    before do
      stub_feature_flags(feature_flag => true)
    end

    it 'measure service execution with Gitlab::Utils::Measuring', :aggregate_failures do
      expect(Gitlab::Utils::Measuring).to receive(:new).with(base_log_data).and_return(measuring)
      expect(measuring).to receive(:with_measuring).and_call_original
    end
  end

  context 'when measurement is disabled' do
    it 'does not measure service execution' do
      stub_feature_flags(feature_flag => false)

      expect(Gitlab::Utils::Measuring).not_to receive(:new)
    end
  end

  def feature_flag
    "gitlab_service_measuring_#{described_class_name}"
  end

  def described_class_name
    described_class.name.underscore.tr('/', '_')
  end
end
