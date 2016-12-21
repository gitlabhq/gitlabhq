require 'openssl'
require 'base64'

#
# Copyright:: Copyright (c) 2015 Chris Marchesi
# Copyright:: Copyright (c) 2016 GitLab Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
class SSHKeygen
  class << self
    def generate
      "ssh-rsa #{openssh_rsa_public_key(generate_private_key)}"
    end

    private

    def generate_private_key
      ::OpenSSL::PKey::RSA.new(2048)
    end

    # Encode an OpenSSH RSA public key.
    # Key format is PEM-encoded - size (big-endian), then data:
    #  * Type (ie: len: 7 (size of string), data: ssh-rsa)
    #  * Exponent (len/data)
    #  * Modulus (len+1/NUL+data)
    def openssh_rsa_public_key(private_key)
      enc_type = "#{[7].pack('N')}ssh-rsa"
      enc_exponent = "#{[private_key.public_key.e.num_bytes].pack('N')}#{private_key.public_key.e.to_s(2)}"
      enc_modulus = "#{[private_key.public_key.n.num_bytes + 1].pack('N')}\0#{private_key.public_key.n.to_s(2)}"
      Base64.strict_encode64("#{enc_type}#{enc_exponent}#{enc_modulus}")
    end
  end
end
