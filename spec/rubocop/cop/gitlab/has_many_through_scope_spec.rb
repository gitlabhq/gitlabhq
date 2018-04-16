require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/gitlab/has_many_through_scope'

describe RuboCop::Cop::Gitlab::HasManyThroughScope do # rubocop:disable RSpec/FilePath
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in a model file' do
    before do
      allow(cop).to receive(:in_model?).and_return(true)
    end

    context 'when the model does not use has_many :through' do
      it 'does not register an offense' do
        expect_no_offenses(<<-RUBY)
          class User < ActiveRecord::Base
            has_many :tags, source: 'UserTag'
          end
        RUBY
      end
    end

    context 'when the model uses has_many :through' do
      context 'when the association has no scope defined' do
        it 'registers an offense on the association' do
          expect_offense(<<-RUBY)
            class User < ActiveRecord::Base
              has_many :tags, through: :user_tags
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
            end
           RUBY
        end
      end

      context 'when the association has a scope defined' do
        context 'when the scope does not disable auto-loading' do
          it 'registers an offense on the scope' do
            expect_offense(<<-RUBY)
              class User < ActiveRecord::Base
                has_many :tags, -> { where(active: true) }, through: :user_tags
                                ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
              end
             RUBY
          end
        end

        context 'when the scope has auto_include(false)' do
          it 'does not register an offense' do
            expect_no_offenses(<<-RUBY)
              class User < ActiveRecord::Base
                has_many :tags, -> { where(active: true).auto_include(false).reorder(nil) }, through: :user_tags
              end
            RUBY
          end
        end
      end
    end
  end

  context 'outside of a migration spec file' do
    it 'does not register an offense' do
      expect_no_offenses(<<-RUBY)
        class User < ActiveRecord::Base
          has_many :tags, through: :user_tags
        end
      RUBY
    end
  end
end
