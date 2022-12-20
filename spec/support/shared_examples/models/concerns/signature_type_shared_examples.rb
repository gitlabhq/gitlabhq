# frozen_string_literal: true

METHODS = %i[
  gpg?
  ssh?
  x509?
].freeze

RSpec.shared_examples 'signature with type checking' do |type|
  describe 'signature type checkers' do
    where(:method, :expected) do
      METHODS.map do |method|
        [method, method == "#{type}?".to_sym]
      end
    end

    with_them do
      specify { expect(subject.public_send(method)).to eq(expected) }
    end
  end
end
