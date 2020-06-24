# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PhabricatorImport::Representation::User do
  subject(:user) do
    described_class.new(
      {
        'phid' => 'the-phid',
        'fields' => {
          'username' => 'the-username'
        }
      }
    )
  end

  describe '#phabricator_id' do
    it 'returns the phabricator id' do
      expect(user.phabricator_id).to eq('the-phid')
    end
  end

  describe '#username' do
    it 'returns the username' do
      expect(user.username).to eq('the-username')
    end
  end
end
