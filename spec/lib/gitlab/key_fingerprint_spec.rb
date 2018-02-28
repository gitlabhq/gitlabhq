require 'spec_helper'

describe Gitlab::KeyFingerprint, lib: true do
  KEYS = {
    rsa:
      'example.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5z65PwQ1GE6foJgwk' \
      '9rmQi/glaXbUeVa5uvQpnZ3Z5+forcI7aTngh3aZ/H2UDP2L70TGy7kKNyp0J3a8/OdG' \
      'Z08y5yi3JlbjFARO1NyoFEjw2H1SJxeJ43L6zmvTlu+hlK1jSAlidl7enS0ufTlzEEj4' \
      'iJcuTPKdVzKRgZuTRVm9woWNVKqIrdRC0rJiTinERnfSAp/vNYERMuaoN4oJt8p/NEek' \
      'rmFoDsQOsyDW5RAnCnjWUU+jFBKDpfkJQ1U2n6BjJewC9dl6ODK639l3yN4WOLZEk4tN' \
      'UysfbGeF3rmMeflaD6O1Jplpv3YhwVGFNKa7fMq6k3Z0tszTJPYh',
    ecdsa:
      'example.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAI' \
      'bmlzdHAyNTYAAABBBKTJy43NZzJSfNxpv/e2E6Zy3qoHoTQbmOsU5FEfpWfWa1MdTeXQ' \
      'YvKOi+qz/1AaNx6BK421jGu74JCDJtiZWT8=',
    ed25519:
      '@revoked example.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjq' \
      'uxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf',
    dss:
      'example.com ssh-dss AAAAB3NzaC1kc3MAAACBAP1/U4EddRIpUt9KnC7s5Of2EbdS' \
      'PO9EAMMeP4C2USZpRV1AIlH7WT2NWPq/xfW6MPbLm1Vs14E7gB00b/JmYLdrmVClpJ+f' \
      '6AR7ECLCT7up1/63xhv4O1fnxqimFQ8E+4P208UewwI1VBNaFpEy9nXzrith1yrv8iID' \
      'GZ3RSAHHAAAAFQCXYFCPFSMLzLKSuYKi64QL8Fgc9QAAAIEA9+GghdabPd7LvKtcNrhX' \
      'uXmUr7v6OuqC+VdMCz0HgmdRWVeOutRZT+ZxBxCBgLRJFnEj6EwoFhO3zwkyjMim4TwW' \
      'eotUfI0o4KOuHiuzpnWRbqN/C/ohNWLx+2J6ASQ7zKTxvqhRkImog9/hWuWfBpKLZl6A' \
      'e1UlZAFMO/7PSSoAAACBAJcQ4JODqhuGbXIEpqxetm7PWbdbCcr3y/GzIZ066pRovpL6' \
      'qm3qCVIym4cyChxWwb8qlyCIi+YRUUWm1z/wiBYT2Vf3S4FXBnyymCkKEaV/EY7+jd4X' \
      '1bXI58OD2u+bLCB/sInM4fGB8CZUIWT9nJH0Ve9jJUge2ms348/QOJ1+'
  }.freeze

  MD5_FINGERPRINTS = {
    rsa: '06:b2:8a:92:df:0e:11:2c:ca:7b:8f:a4:ba:6e:4b:fd',
    ecdsa: '45:ff:5b:98:9a:b6:8a:41:13:c1:30:8b:09:5e:7b:4e', 
    ed25519: '2e:65:6a:c8:cf:bf:b2:8b:9a:bd:6d:9f:11:5c:12:16', 
    dss: '57:98:86:02:5f:9c:f4:9b:ad:5a:1e:51:92:0e:fd:2b'
  }.freeze

  BIT_COUNTS = {
    rsa: 2048,
    ecdsa: 256,
    ed25519: 256,
    dss: 1024
  }.freeze

  describe '#type' do
    KEYS.each do |type, key|
      it "calculates the type of #{type} keys" do
        calculated_type = described_class.new(key).type

        expect(calculated_type).to eq(type.to_s.upcase)
      end
    end
  end

  describe '#fingerprint' do
    KEYS.each do |type, key|
      it "calculates the MD5 fingerprint for #{type} keys" do
        fp = described_class.new(key).fingerprint

        expect(fp).to eq(MD5_FINGERPRINTS[type])
      end
    end
  end

  describe '#bits' do
    KEYS.each do |type, key|
      it "calculates the number of bits in #{type} keys" do
        bits = described_class.new(key).bits

        expect(bits).to eq(BIT_COUNTS[type])
      end
    end
  end

  describe '#key' do
    it 'carries the unmodified key data' do
      key = described_class.new(KEYS[:rsa]).key

      expect(key).to eq(KEYS[:rsa])
    end
  end
end
