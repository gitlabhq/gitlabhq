# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::DeployKeyAuthor do
  describe '#initialize' do
    it 'sets correct attributes' do
      expect(described_class.new(name: 'Lorem deploy key'))
        .to have_attributes(id: -3, name: 'Lorem deploy key')
    end

    it 'sets default name when it is not provided' do
      expect(described_class.new)
        .to have_attributes(id: -3, name: 'Deploy key')
    end
  end
end
