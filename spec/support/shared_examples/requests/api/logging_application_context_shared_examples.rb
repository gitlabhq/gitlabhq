# frozen_string_literal: true

RSpec.shared_examples 'storing arguments in the application context' do
  around do |example|
    Labkit::Context.with_context { example.run }
  end

  it 'places the expected params in the application context' do
    # Stub the clearing of the context so we can validate it later
    # The `around` block above makes sure we do clean it up later
    allow(Labkit::Context).to receive(:pop)

    subject

    Labkit::Context.with_context do |context|
      expect(context.to_h)
        .to include(log_hash(expected_params))
    end
  end

  def log_hash(hash)
    hash.transform_keys! { |key| "meta.#{key}" }
  end
end
