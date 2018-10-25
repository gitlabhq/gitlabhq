# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20181026091631_migrate_forbidden_redirect_uris.rb')

describe MigrateForbiddenRedirectUris, :migration do
  let(:oauth_application) { table(:oauth_applications) }
  let(:oauth_access_grant) { table(:oauth_access_grants) }

  let!(:control_app) { oauth_application.create(random_params) }
  let!(:control_access_grant) { oauth_application.create(random_params) }
  let!(:forbidden_js_app) { oauth_application.create(random_params.merge(redirect_uri: 'javascript://alert()')) }
  let!(:forbidden_vb_app) { oauth_application.create(random_params.merge(redirect_uri: 'VBSCRIPT://alert()')) }
  let!(:forbidden_access_grant) { oauth_application.create(random_params.merge(redirect_uri: 'vbscript://alert()')) }

  context 'oauth application' do
    it 'migrates forbidden javascript URI' do
      expect { migrate! }.to change { forbidden_js_app.reload.redirect_uri }.to('http://forbidden-scheme-has-been-overwritten')
    end

    it 'migrates forbidden VBScript URI' do
      expect { migrate! }.to change { forbidden_vb_app.reload.redirect_uri }.to('http://forbidden-scheme-has-been-overwritten')
    end

    it 'does not migrate a valid URI' do
      expect { migrate! }.not_to change { control_app.reload.redirect_uri }
    end
  end

  context 'access grant' do
    it 'migrates forbidden VBScript URI' do
      expect { migrate! }.to change { forbidden_access_grant.reload.redirect_uri }.to('http://forbidden-scheme-has-been-overwritten')
    end

    it 'does not migrate a valid URI' do
      expect { migrate! }.not_to change { control_access_grant.reload.redirect_uri }
    end
  end

  def random_params
    {
      name: 'test',
      secret: 'test',
      uid: Doorkeeper::OAuth::Helpers::UniqueToken.generate,
      redirect_uri: 'http://valid.com'
    }
  end
end
