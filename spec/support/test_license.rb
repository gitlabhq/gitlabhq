class TestLicense
  def self.init
    Gitlab::License.encryption_key = OpenSSL::PKey::RSA.generate(2048)

    FactoryGirl.create(:license)
  end

  def self.destroy!
    License.destroy_all
  end
end
