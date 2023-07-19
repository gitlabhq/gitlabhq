# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/ignored_columns'

RSpec.describe RuboCop::Cop::IgnoredColumns, feature_category: :database do
  it 'flags use of `self.ignored_columns +=` instead of the IgnorableColumns concern' do
    expect_offense(<<~RUBY)
      class Foo < ApplicationRecord
        self.ignored_columns += %i[id]
             ^^^^^^^^^^^^^^^ Use `IgnorableColumns` concern instead of adding to `self.ignored_columns`.
      end
    RUBY
  end

  it 'flags use of `self.ignored_columns =` instead of the IgnorableColumns concern' do
    expect_offense(<<~RUBY)
      class Foo < ApplicationRecord
        self.ignored_columns = %i[id]
             ^^^^^^^^^^^^^^^ Use `IgnorableColumns` concern instead of setting `self.ignored_columns`.
      end
    RUBY
  end

  context 'when only CE model exist' do
    let(:file_path) { full_path('app/models/bar.rb') }

    it 'does not flag `ignore_columns` usage in CE model' do
      expect_no_offenses(<<~RUBY, file_path)
        class Bar < ApplicationRecord
          ignore_columns :foo, remove_with: '14.3', remove_after: '2021-09-22'
        end
      RUBY
    end

    it 'does not flag `ignore_column` usage in CE model' do
      expect_no_offenses(<<~RUBY, file_path)
        class Baz < ApplicationRecord
          ignore_column :bar, remove_with: '14.3', remove_after: '2021-09-22'
        end
      RUBY
    end
  end

  context 'when only EE model exist' do
    let(:file_path) { full_path('ee/app/models/ee/bar.rb') }

    before do
      allow(File).to receive(:exist?).with(full_path('app/models/bar.rb')).and_return(false)
    end

    it 'does not flag `ignore_columns` usage in EE model' do
      expect_no_offenses(<<~RUBY, file_path)
        class Bar < ApplicationRecord
          ignore_columns :foo, remove_with: '14.3', remove_after: '2021-09-22'
        end
      RUBY
    end

    it 'does not flag `ignore_column` usage in EE model' do
      expect_no_offenses(<<~RUBY, file_path)
        class Bar < ApplicationRecord
          ignore_column :foo, remove_with: '14.3', remove_after: '2021-09-22'
        end
      RUBY
    end
  end

  context 'when CE and EE model exist' do
    let(:file_path) { full_path('ee/app/models/ee/bar.rb') }

    before do
      allow(File).to receive(:exist?).with(full_path('app/models/bar.rb')).and_return(true)
    end

    it 'flags `ignore_columns` usage in EE model' do
      expect_offense(<<~RUBY, file_path)
        class Bar < ApplicationRecord
          ignore_columns :foo, remove_with: '14.3', remove_after: '2021-09-22'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ If the model exists in CE and EE, [...]
        end
      RUBY
    end

    it 'flags `ignore_column` usage in EE model' do
      expect_offense(<<~RUBY, file_path)
        class Bar < ApplicationRecord
          ignore_column :foo, remove_with: '14.3', remove_after: '2021-09-22'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ If the model exists in CE and EE, [...]
        end
      RUBY
    end
  end

  private

  def full_path(path)
    rails_root = '../../../'

    File.expand_path(File.join(rails_root, path), __dir__)
  end
end
