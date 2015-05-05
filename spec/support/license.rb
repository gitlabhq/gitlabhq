RSpec.configure do |config|
  config.before(:all) do
    Gitlab::License.encryption_key = OpenSSL::PKey::RSA.generate(2048)

    FactoryGirl.create(:license)
  end
end
