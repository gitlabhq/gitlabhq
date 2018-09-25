# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/code_reuse/active_record'

describe RuboCop::Cop::CodeReuse::ActiveRecord do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags the use of "where" without any arguments' do
    expect_offense(<<~SOURCE)
    def foo
      User.where
           ^^^^^ This method can only be used inside an ActiveRecord model
    end
    SOURCE
  end

  it 'flags the use of "where" with arguments' do
    expect_offense(<<~SOURCE)
    def foo
      User.where(id: 10)
           ^^^^^ This method can only be used inside an ActiveRecord model
    end
    SOURCE
  end

  it 'does not flag the use of "group" without any arguments' do
    expect_no_offenses(<<~SOURCE)
    def foo
      project.group
    end
    SOURCE
  end

  it 'flags the use of "group" with arguments' do
    expect_offense(<<~SOURCE)
    def foo
      project.group(:name)
              ^^^^^ This method can only be used inside an ActiveRecord model
    end
    SOURCE
  end

  it 'does not flag the use of ActiveRecord models in a model' do
    path = Rails.root.join('app', 'models', 'foo.rb').to_s

    expect_no_offenses(<<~SOURCE, path)
    def foo
      project.group(:name)
    end
    SOURCE
  end

  it 'does not flag the use of ActiveRecord models in a spec' do
    path = Rails.root.join('spec', 'foo_spec.rb').to_s

    expect_no_offenses(<<~SOURCE, path)
    def foo
      project.group(:name)
    end
    SOURCE
  end

  it 'does not flag the use of ActiveRecord models in a background migration' do
    path = Rails
      .root
      .join('lib', 'gitlab', 'background_migration', 'foo.rb')
      .to_s

    expect_no_offenses(<<~SOURCE, path)
    def foo
      project.group(:name)
    end
    SOURCE
  end

  it 'does not flag the use of ActiveRecord models in lib/gitlab/database' do
    path = Rails.root.join('lib', 'gitlab', 'database', 'foo.rb').to_s

    expect_no_offenses(<<~SOURCE, path)
    def foo
      project.group(:name)
    end
    SOURCE
  end

  it 'autocorrects offenses in instance methods by whitelisting them' do
    corrected = autocorrect_source(<<~SOURCE)
    def foo
      User.where
    end
    SOURCE

    expect(corrected).to eq(<<~SOURCE)
    # rubocop: disable CodeReuse/ActiveRecord
    def foo
      User.where
    end
    # rubocop: enable CodeReuse/ActiveRecord
    SOURCE
  end

  it 'autocorrects offenses in class methods by whitelisting them' do
    corrected = autocorrect_source(<<~SOURCE)
    def self.foo
      User.where
    end
    SOURCE

    expect(corrected).to eq(<<~SOURCE)
    # rubocop: disable CodeReuse/ActiveRecord
    def self.foo
      User.where
    end
    # rubocop: enable CodeReuse/ActiveRecord
    SOURCE
  end

  it 'autocorrects offenses in blocks by whitelisting them' do
    corrected = autocorrect_source(<<~SOURCE)
    get '/' do
      User.where
    end
    SOURCE

    expect(corrected).to eq(<<~SOURCE)
    # rubocop: disable CodeReuse/ActiveRecord
    get '/' do
      User.where
    end
    # rubocop: enable CodeReuse/ActiveRecord
    SOURCE
  end
end
