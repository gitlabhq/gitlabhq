# frozen_string_literal: true

# These shared_examples require the following variables:
# - text: The text to be run through the filter
#
# Usage:
#
#   it_behaves_like 'html filter timeout' do
#     let(:text) { 'some text' }
#   end
RSpec.shared_examples 'html filter timeout' do
  context 'when rendering takes too long' do
    let_it_be(:project) { create(:project) }
    let_it_be(:context) { { project: project } }

    it 'times out' do
      stub_const("Banzai::Filter::TimeoutHtmlPipelineFilter::RENDER_TIMEOUT", 0.1)
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:call_with_timeout) do
          sleep(0.2)
          text
        end
      end

      expect(Gitlab::RenderTimeout).to receive(:timeout).and_call_original
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        instance_of(Timeout::Error),
        project_id: context[:project].id,
        class_name: described_class.name.demodulize
      )

      result = filter(text)

      expect(result.to_html).to eq text
    end
  end
end

# Usage:
#
#   it_behaves_like 'text html filter timeout' do
#     let(:text) { 'some text' }
#   end
RSpec.shared_examples 'text filter timeout' do
  context 'when rendering takes too long' do
    let_it_be(:project) { create(:project) }
    let_it_be(:context) { { project: project } }

    it 'times out' do
      stub_const("Banzai::Filter::TimeoutTextPipelineFilter::RENDER_TIMEOUT", 0.1)
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:call_with_timeout) do
          sleep(0.2)
          text
        end
      end

      expect(Gitlab::RenderTimeout).to receive(:timeout).and_call_original
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        instance_of(Timeout::Error),
        project_id: context[:project].id,
        class_name: described_class.name.demodulize
      )

      result = filter(text)

      expect(result).to eq text
    end
  end
end

# Usage:
#
#   it_behaves_like 'a filter timeout' do
#     let(:text) { 'some text' }
#     let(:expected_result) { 'optional result text' }
#   end
RSpec.shared_examples 'a filter timeout' do
  context 'when rendering takes too long' do
    let_it_be(:project) { create(:project) }
    let_it_be(:context) { { project: project } }

    it 'times out' do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:render_timeout).and_return(0.1)
        allow(instance).to receive(:call_with_timeout) do
          sleep(0.2)
          text
        end
      end

      expect(Gitlab::RenderTimeout).to receive(:timeout).and_call_original
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        instance_of(Timeout::Error),
        project_id: context[:project].id,
        class_name: described_class.name.demodulize
      )

      result = filter(text)
      result = result.to_html if result.respond_to?(:to_html)

      if defined?(expected_result)
        expect(result).to eq expected_result
      else
        expect(result).to eq text
      end
    end
  end
end

# Usage:
#
#   it_behaves_like 'not a filter timeout' do
#     let(:text) { 'some text' }
#   end
RSpec.shared_examples 'not a filter timeout' do
  it 'does not use Gitlab::RenderTimeout' do
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:call_with_timeout) do
        sleep(0.2)
        text
      end
    end

    expect(Gitlab::RenderTimeout).not_to receive(:timeout).and_call_original

    filter(text)
  end
end

# Usage:
#
#   it_behaves_like 'pipeline timing check'
RSpec.shared_examples 'pipeline timing check' do |context: {}|
  it 'checks the pipeline timing' do
    expect_next_instance_of(described_class) do |instance|
      expect(instance).to receive(:exceeded_pipeline_max?).and_return(true)
    end

    filter = described_class.new('text', context)
    filter.call
  end
end
