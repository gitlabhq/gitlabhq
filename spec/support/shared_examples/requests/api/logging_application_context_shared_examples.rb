# frozen_string_literal: true

RSpec.shared_examples 'storing arguments in the application context' do
  it 'places the expected params in the application context' do
    # Stub the clearing of the context so we can validate it later
    allow(Labkit::Context).to receive(:pop)

    subject

    expect(Gitlab::ApplicationContext.current).to include(log_hash(expected_params))
  end

  def log_hash(hash)
    hash.transform_keys! { |key| "meta.#{key}" }
  end
end

RSpec.shared_examples 'not executing any extra queries for the application context' do |expected_extra_queries = 0|
  it 'does not execute more queries than without adding anything to the application context' do
    # Call the subject once to memoize all factories being used for the spec, so they won't
    # add any queries to the expectation.
    subject_proc.call

    expect do
      allow(Gitlab::ApplicationContext).to receive(:push).and_call_original
      subject_proc.call
    end.to issue_same_number_of_queries_as {
      allow(Gitlab::ApplicationContext).to receive(:push)
      subject_proc.call
    }.with_threshold(expected_extra_queries).ignoring_cached_queries
  end
end
