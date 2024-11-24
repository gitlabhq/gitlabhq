# frozen_string_literal: true

module DoorkeeperConfiguration
  def configure_doorkeeper(signing_key, signing_algorithm)
    Doorkeeper::OpenidConnect.configure do
      signing_key signing_key

      signing_algorithm signing_algorithm

      resource_owner_from_access_token do |access_token|
        User.find_by(id: access_token.resource_owner_id)
      end

      auth_time_from_resource_owner do |resource_owner|
        resource_owner.current_sign_in_at
      end

      subject do |resource_owner|
        resource_owner.id
      end
    end
  end

  def configure_ec
    signing_key = <<~EOL
      -----BEGIN EC PRIVATE KEY-----
      MIHbAgEBBEF9VcxGjPKczrJlE1N3oEpZsauQfDXIjLeini7h4/3+DOKw2VWE4lCU
      rNJJL65EHT+2TriRg2xSb0l0rK/MAFAFraAHBgUrgQQAI6GBiQOBhgAEAeYVvbl3
      zZcFCdE+0msqOowYODjzeXAhjsZKhdNjGlDREvko3UFOw6S43g+s8bvVBmBz3fCo
      dEzFRYQqJVI4UFvFAYJ7GYeBm/Fb6liN53xGASdbRSzF34h4BDSVYzjtQc7I+1LK
      17fwwS3VfQCJwaT6zX33HTrhR4VoUEUJHKwR3dNs
      -----END EC PRIVATE KEY-----
    EOL
    configure_doorkeeper(signing_key, :ES512)
  end

  def configure_hmac
    configure_doorkeeper('the_greatest_secret_key', :HS512)
  end
end

RSpec.configure { |config| config.include DoorkeeperConfiguration }
