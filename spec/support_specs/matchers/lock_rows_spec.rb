# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'lock_rows', :lock_recorder, feature_category: :database do
  let!(:users) { create_list(:user, 2) }
  let!(:user) { users.first }

  describe 'ActiveRecord::Locking::Pessimistic.lock!' do
    it { expect { user.lock! }.to lock_rows(user => 'FOR UPDATE') }

    it { expect { user.lock!('FOR SHARE') }.to lock_rows(user => 'FOR SHARE') }
  end

  describe 'ActiveRecord::Persistence#reload' do
    it { expect { user.reload(lock: 'FOR SHARE') }.to lock_rows(user => 'FOR SHARE') }
  end

  describe 'ActiveRecord::Locking::Pessimistic#lock!' do
    it { expect { User.all.lock!('FOR SHARE').load }.to lock_rows(users[0] => 'FOR SHARE', users[1] => 'FOR SHARE') }
  end

  describe 'ActiveRecord::Relation#lock' do
    it { expect { User.lock.find(user.id) }.to lock_rows(user => 'FOR UPDATE') }
  end
end
