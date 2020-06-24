# frozen_string_literal: true

RSpec.shared_examples 'raise exception if not implemented' do
  it { expect { described_class.new(project).imported_items_cache_key }.not_to raise_error }
end
