# frozen_string_literal: true

RSpec.shared_context 'with invalid Rubygems metadata' do
  before do
    allow_next_instance_of(::Packages::Rubygems::MetadataExtractionService) do |instance|
      allow(instance).to receive(:execute).and_raise(ActiveRecord::StatementInvalid)
    end
  end
end
