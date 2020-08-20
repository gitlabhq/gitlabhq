# frozen_string_literal: true

RSpec.shared_context 'CSV response' do
  let(:csv_response) { CSV.parse(response.body) }
end
