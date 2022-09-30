# frozen_string_literal: true
require 'spec_helper'
require 'sawyer'

require_relative '../../config/initializers/sawyer_patch'

RSpec.describe 'sawyer_patch' do
  it 'raises error when acessing a method that overlaps a Ruby method' do
    sawyer_resource = Sawyer::Resource.new(
      Sawyer::Agent.new(''),
      {
        to_s: 'Overriding method',
        user: { to_s: 'Overriding method', name: 'User name' }
      }
    )

    error_message = 'Sawyer method "to_s" overlaps Ruby method. Convert to a hash to access the attribute.'
    expect { sawyer_resource.to_s }.to raise_error(Sawyer::Error, error_message)
    expect { sawyer_resource.to_s? }.to raise_error(Sawyer::Error, error_message)
    expect { sawyer_resource.to_s = 'new value' }.to raise_error(Sawyer::Error, error_message)
    expect { sawyer_resource.user.to_s }.to raise_error(Sawyer::Error, error_message)
    expect(sawyer_resource.user.name).to eq('User name')
  end

  it 'raises error when acessing a boolean method that overlaps a Ruby method' do
    sawyer_resource = Sawyer::Resource.new(
      Sawyer::Agent.new(''),
      {
        nil?: 'value'
      }
    )

    expect { sawyer_resource.nil? }.to raise_error(Sawyer::Error)
  end

  it 'raises error when acessing a method that expects an argument' do
    sawyer_resource = Sawyer::Resource.new(
      Sawyer::Agent.new(''),
      {
        'user': 'value',
        'user=': 'value',
        '==': 'value',
        '!=': 'value',
        '+': 'value'
      }
    )

    expect(sawyer_resource.user).to eq('value')
    expect { sawyer_resource.user = 'New user' }.to raise_error(ArgumentError)
    expect { sawyer_resource == true }.to raise_error(ArgumentError)
    expect { sawyer_resource != true }.to raise_error(ArgumentError)
    expect { sawyer_resource + 1 }.to raise_error(ArgumentError)
  end

  it 'does not raise error if is not an overlapping method' do
    sawyer_resource = Sawyer::Resource.new(
      Sawyer::Agent.new(''),
      {
        count_total: 1,
        user: { name: 'User name' }
      }
    )

    expect(sawyer_resource.count_total).to eq(1)
    expect(sawyer_resource.count_total?).to eq(true)
    expect(sawyer_resource.count_total + 1).to eq(2)
    sawyer_resource.count_total = 3
    expect(sawyer_resource.count_total).to eq(3)
    expect(sawyer_resource.user.name).to eq('User name')
  end

  it 'logs when a sawyer resource dynamic method is called' do
    sawyer_resource = Sawyer::Resource.new(
      Sawyer::Agent.new(''),
      {
        count_total: 1,
        user: { name: 'User name' }
      }
    )
    expected_attributes = []
    allow(Gitlab::Import::Logger).to receive(:warn) do |params|
      expected_attributes.push(params[:attribute])
    end

    sawyer_resource.count_total
    sawyer_resource.user
    sawyer_resource.user.name

    expect(expected_attributes).to match_array(%i[count_total user user name])
  end
end
