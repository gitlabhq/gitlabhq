# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OpenidConnect::AccessGrant do
  subject { Doorkeeper::AccessGrant.new }

  it 'has one openid_request' do
    association = subject.class.reflect_on_association :openid_request

    expect(association.options).to eq({
      class_name: 'Doorkeeper::OpenidConnect::Request',
      inverse_of: :access_grant,
      foreign_key: "access_grant_id",
      dependent: :delete,
    })
  end

  it 'extends the base doorkeeper AccessGrant' do
    expect(subject).to respond_to(:"openid_request=")
  end

  describe '#delete' do
    it 'cascades to oauth_openid_requests' do
      if Rails::VERSION::MAJOR >= 6
        access_grant = create(:access_grant, application: create(:application))
        create(:openid_request, access_grant: access_grant)

        expect { access_grant.delete }
          .to(change { Doorkeeper::OpenidConnect::Request.count }.by(-1))
      else
        skip <<-MSG.strip
          Needs Rails 6 for foreign key support with sqlite3:
          https://blog.bigbinary.com/2019/09/24/rails-6-adds-add_foreign_key-and-remove_foreign_key-for-sqlite3.html
        MSG
      end
    end
  end
end
