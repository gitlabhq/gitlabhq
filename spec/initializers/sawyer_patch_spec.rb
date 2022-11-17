# frozen_string_literal: true

require 'spec_helper'
require 'sawyer'

require_relative '../../config/initializers/sawyer_patch'

RSpec.describe 'sawyer_patch' do
  it 'raises error when acessing Sawyer Resource dynamic methods' do
    sawyer_resource = Sawyer::Resource.new(
      Sawyer::Agent.new(''),
      {
        to_s: 'Overriding method',
        nil?: 'value',
        login: 'Login',
        user: { to_s: 'Overriding method', name: 'User name' }
      }
    )

    expect { sawyer_resource.to_s }.to raise_error(Sawyer::Error)
    expect { sawyer_resource.to_s? }.to raise_error(Sawyer::Error)
    expect { sawyer_resource.to_s = 'new value' }.to raise_error(Sawyer::Error)
    expect { sawyer_resource.nil? }.to raise_error(Sawyer::Error)
    expect { sawyer_resource.user.to_s }.to raise_error(Sawyer::Error)
    expect { sawyer_resource.login }.to raise_error(Sawyer::Error)
    expect { sawyer_resource.login? }.to raise_error(Sawyer::Error)
    expect { sawyer_resource.login = 'New value' }.to raise_error(Sawyer::Error)
    expect { sawyer_resource.user.name }.to raise_error(Sawyer::Error)
    expect { sawyer_resource.user.name? }.to raise_error(Sawyer::Error)
    expect { sawyer_resource.user.name = 'New value' }.to raise_error(Sawyer::Error)
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

    expect { sawyer_resource == true }.to raise_error(ArgumentError)
    expect { sawyer_resource != true }.to raise_error(ArgumentError)
    expect { sawyer_resource + 1 }.to raise_error(ArgumentError)
  end
end
