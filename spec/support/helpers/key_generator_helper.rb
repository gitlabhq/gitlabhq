# frozen_string_literal: true

module Spec
  module Support
    module Helpers
      class KeyGeneratorHelper
        # The components in a openssh .pub / known_host RSA public key.
        RSA_COMPONENTS = ['ssh-rsa', :e, :n].freeze

        attr_reader :size

        def initialize(size = 2048)
          @size = size
        end

        def generate
          key = OpenSSL::PKey::RSA.generate(size)
          components = RSA_COMPONENTS.map do |component|
            key.respond_to?(component) ? encode_mpi(key.public_send(component)) : component
          end

          # Ruby tries to be helpful and adds new lines every 60 bytes :(
          'ssh-rsa ' + [pack_pubkey_components(components)].pack('m').delete("\n")
        end

        private

        # Encodes an openssh-mpi-encoded integer.
        def encode_mpi(n) # rubocop:disable Naming/UncommunicativeMethodParamName
          chars = []
          n = n.to_i
          chars << (n & 0xff) && n >>= 8 while n != 0
          chars << 0 if chars.empty? || chars.last >= 0x80
          chars.reverse.pack('C*')
        end

        # Packs string components into an openssh-encoded pubkey.
        def pack_pubkey_components(strings)
          (strings.flat_map { |s| [s.length].pack('N') }).zip(strings).join
        end
      end
    end
  end
end
