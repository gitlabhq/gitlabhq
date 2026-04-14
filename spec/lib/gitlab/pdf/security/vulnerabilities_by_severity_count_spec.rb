# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::PDF::Security::VulnerabilitiesBySeverityCount, feature_category: :vulnerability_management do
  let(:pdf) { Prawn::Document.new }

  let(:data) do
    {
      critical: { count: 18, medianAge: 96.0641123249309, color: "#dd2b0e" },
      high: { count: 74, medianAge: 55.74285336651738, color: "#f6806d" },
      medium: { count: 91, medianAge: 96.06411232475729, color: "#d99530" },
      low: { count: 8, medianAge: 96.06411232458369, color: "#f5d9a8" },
      info: { count: 7, medianAge: 85, color: "#63a6e9" },
      unknown: { count: 26, medianAge: 55.74285336613543, color: "#a4a3a8" }
    }
  end

  describe '.render' do
    it 'renders without error' do
      expect { described_class.render(pdf, data: data) }.not_to raise_error
    end

    it 'renders without error when data is nil' do
      expect { described_class.render(pdf, data: nil) }.not_to raise_error
    end

    it 'renders boxes based on severities constant length' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:draw_severity_box)
          .exactly(described_class::SEVERITIES.length).times
          .and_call_original
      end

      described_class.render(pdf, data: data)
    end

    context 'when severity box count is nil' do
      let(:data_with_nil_count) { data.deep_merge(critical: { count: nil }) }

      it 'does not render median age' do
        total_boxes = described_class::SEVERITIES.length
        expected_calls = total_boxes - 1

        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:draw_median_age)
            .exactly(expected_calls).times
            .and_call_original
        end

        described_class.render(pdf, data: data_with_nil_count)
      end
    end

    context 'when a severity box count is 0' do
      let(:data_with_zero_count) { data.deep_merge(critical: { count: 0 }) }

      it 'does not render median age' do
        total_boxes = described_class::SEVERITIES.length
        expected_calls = total_boxes - 1

        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:draw_median_age)
            .exactly(expected_calls).times
            .and_call_original
        end

        described_class.render(pdf, data: data_with_zero_count)
      end
    end

    context 'when median age is nil' do
      let(:data_with_nil_median_age) { data.deep_merge(critical: { medianAge: nil }) }

      it 'does not render median age' do
        total_boxes = described_class::SEVERITIES.length
        expected_calls = total_boxes - 1

        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:draw_median_age)
            .exactly(expected_calls).times
            .and_call_original
        end

        described_class.render(pdf, data: data_with_nil_median_age)
      end
    end

    context 'when rendering count text' do
      it 'renders the correct count for a severity' do
        allow(pdf).to receive(:text_box).and_call_original
        expect(pdf).to receive(:text_box).with('18', anything).and_call_original

        described_class.render(pdf, data: data)
      end

      it 'renders 0 when count is nil' do
        allow(pdf).to receive(:text_box).and_call_original
        expect(pdf).to receive(:text_box).with('0', anything).and_call_original

        described_class.render(pdf, data: data.deep_merge(critical: { count: nil }))
      end
    end

    context 'when rendering median age text' do
      it 'renders the correct median age text for a severity' do
        allow(pdf).to receive(:text_box).and_call_original
        expect(pdf).to receive(:text_box).with('Median: 97 days', anything).and_call_original

        described_class.render(pdf, data: data)
      end

      it 'renders the correct median age text when medianAge is a string' do
        allow(pdf).to receive(:text_box).and_call_original
        expect(pdf).to receive(:text_box).with('Median: 97 days', anything).and_call_original

        described_class.render(pdf, data: data.deep_merge(critical: { medianAge: '96.0641123249309' }))
      end
    end

    context 'when rendering severity titles' do
      it 'renders each severity title capitalized' do
        allow(pdf).to receive(:text_box).and_call_original

        described_class::SEVERITIES.each do |severity|
          expect(pdf).to receive(:text_box).with(severity.to_s.capitalize, anything).and_call_original
        end

        described_class.render(pdf, data: data)
      end
    end

    context 'when drawing severity circles' do
      it 'draws a circle for each severity' do
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:draw_severity_circle)
            .exactly(described_class::SEVERITIES.length).times
            .and_call_original
        end

        described_class.render(pdf, data: data)
      end

      it 'uses the color from severity data, stripping the # prefix' do
        allow(pdf).to receive(:fill_color).and_call_original
        expect(pdf).to receive(:fill_color).with('dd2b0e').and_call_original

        described_class.render(pdf, data: data)
      end

      context 'when color is absent from severity data' do
        let(:data_without_color) { data.transform_values { |v| v.except(:color) } }

        it 'renders without error' do
          expect { described_class.render(pdf, data: data_without_color) }.not_to raise_error
        end

        it 'uses the fallback color for each severity' do
          allow(pdf).to receive(:fill_color).and_call_original

          described_class::SEVERITIES.each do |severity|
            expect(pdf).to receive(:fill_color)
              .with(described_class::FALLBACK_SEVERITY_COLORS[severity])
              .and_call_original
          end

          described_class.render(pdf, data: data_without_color)
        end
      end
    end

    context 'when data is partial' do
      let(:partial_data) { { critical: { count: 5, medianAge: 10.5 } } }

      it 'renders without error' do
        expect { described_class.render(pdf, data: partial_data) }.not_to raise_error
      end

      it 'renders 0 for missing severities' do
        allow(pdf).to receive(:text_box).and_call_original
        expect(pdf).to receive(:text_box).with('0', anything).and_call_original

        described_class.render(pdf, data: partial_data)
      end
    end
  end
end
