# frozen_string_literal: true

# This is an excessive timeout, however it's meant to ensure that we don't
# have flaky timeouts in CI, which can be slow.
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161969
BANZAI_FILTER_TIMEOUT_MAX = 30.seconds

# Usage:
#
#   it_behaves_like 'a filter timeout' do
#     let(:text) { 'some text' }
#     let(:expected_result) { 'optional result text' }
#     let(:expected_timeout) { OVERRIDDEN_TIMEOUT_VALUE }
#   end
RSpec.shared_examples 'a filter timeout' do
  context 'when rendering takes too long' do
    let_it_be(:project) { create(:project) }
    let_it_be(:context) { { project: project } }

    it 'times out' do
      expect(Gitlab::RenderTimeout).to receive(:timeout).and_raise(Timeout::Error)
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        instance_of(Timeout::Error),
        project_id: context[:project].id,
        group_id: nil,
        class_name: described_class.name.demodulize
      )

      result = filter(text)
      result = result.to_html if result.respond_to?(:to_html)

      expected = defined?(expected_result) ? expected_result : text
      expect(result).to eq expected
    end

    it 'verifies render_timeout' do
      timeout = defined?(expected_timeout) ? expected_timeout : described_class::RENDER_TIMEOUT

      expect(described_class.new('Foo', project: nil).send(:render_timeout)).to eq timeout
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
      allow(instance).to receive(:call) do
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

# Usage:
#
#   it_behaves_like 'does not use pipeline timing check'
RSpec.shared_examples 'does not use pipeline timing check' do
  it 'does not include Concerns::PipelineTimingCheck' do
    expect(described_class).not_to include Banzai::Filter::Concerns::PipelineTimingCheck
  end
end

# Usage:
#
#   it_behaves_like 'limits the number of filtered items' do
#     let(:text) { 'some text' }
#     let(:ends_with) { 'result should end with this text' }
#   end
RSpec.shared_examples 'limits the number of filtered items' do |context: {}|
  before do
    stub_const('Banzai::Filter::FILTER_ITEM_LIMIT', 2)
  end

  it 'enforces limits' do
    result = if defined?(filter_result)
               filter_result
             else
               filter(text, context)
             end

    result = result.to_html unless result.is_a?(String)

    expect(result).to end_with ends_with
  end
end
