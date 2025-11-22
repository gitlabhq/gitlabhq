# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::Job, feature_category: :continuous_integration do
  describe '#group_name' do
    using RSpec::Parameterized::TableSyntax
    where(:name, :group_name) do
      'rspec1'                                              | 'rspec1'
      'rspec1 0 1'                                          | 'rspec1'
      'rspec1 0/2'                                          | 'rspec1'
      'rspec:windows'                                       | 'rspec:windows'
      'rspec:windows 0'                                     | 'rspec:windows 0'
      'rspec:windows 0 2/2'                                 | 'rspec:windows 0'
      'rspec:windows 0 test'                                | 'rspec:windows 0 test'
      'rspec:windows 0 test 2/2'                            | 'rspec:windows 0 test'
      'rspec:windows 0 1 2/2'                               | 'rspec:windows'
      'rspec:windows 0 1 [aws] 2/2'                         | 'rspec:windows'
      'rspec:windows 0 1 name [aws] 2/2'                    | 'rspec:windows 0 1 name'
      'rspec:windows 0 1 name'                              | 'rspec:windows 0 1 name'
      'rspec:windows 0 1 name 1/2'                          | 'rspec:windows 0 1 name'
      'rspec:windows 0/1'                                   | 'rspec:windows'
      'rspec:windows 0/1 name'                              | 'rspec:windows 0/1 name'
      'rspec:windows 0/1 name 1/2'                          | 'rspec:windows 0/1 name'
      'rspec:windows 0:1'                                   | 'rspec:windows'
      'rspec:windows 0:1 name'                              | 'rspec:windows 0:1 name'
      'rspec:windows 10000 20000'                           | 'rspec:windows'
      'rspec:windows 0 : / 1'                               | 'rspec:windows'
      'rspec:windows 0 : / 1 name'                          | 'rspec:windows 0 : / 1 name'
      'rspec [inception: [something, other thing], value]'  | 'rspec'
      '0 1 name ruby'                                       | '0 1 name ruby'
      '0 :/ 1 name ruby'                                    | '0 :/ 1 name ruby'
      'rspec: [aws]'                                        | 'rspec'
      'rspec: [aws] 0/1'                                    | 'rspec'
      'rspec: [aws, max memory]'                            | 'rspec'
      'rspec:linux: [aws, max memory, data]'                | 'rspec:linux'
      'rspec: [inception: [something, other thing], value]' | 'rspec'
      'rspec:windows 0/1: [name, other]'                    | 'rspec:windows'
      'rspec:windows: [name, other] 0/1'                    | 'rspec:windows'
      'rspec:windows: [name, 0/1] 0/1'                      | 'rspec:windows'
      'rspec:windows: [0/1, name]'                          | 'rspec:windows'
      'rspec:windows: [, ]'                                 | 'rspec:windows'
      'rspec:windows: [name]'                               | 'rspec:windows'
      'rspec-windows: [name, other, context]'               | 'rspec-windows'
      'rspec_windows: [name,  ]'                            | 'rspec_windows'
      'rspec windows & linux: [ruby, 3.5]'                  | 'rspec windows & linux'
    end

    with_them do
      it "#{params[:name]} puts in #{params[:group_name]}" do
        expect(described_class.group_name(name)).to eq(group_name)
      end
    end
  end
end
