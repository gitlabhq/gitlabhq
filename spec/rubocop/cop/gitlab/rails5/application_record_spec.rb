require "spec_helper"
require "rubocop"
require "rubocop/rspec/support"
require_relative "../../../../../rubocop/cop/gitlab/rails5/application_record"

describe RuboCop::Cop::Gitlab::Rails5::ApplicationRecord do
  include CopHelper

  subject(:cop) { described_class.new }

  let(:code_with_wrong_constants) do
    <<~RUBY
      class User < ActiveRecord::Base
        def connect
          ::ActiveRecord::Base.connection
        end

        def update
          ActiveRecord::Base.update
        end

        def create
          ActiveRecord.create
        end

        def classes
          Class.new(ActiveRecord::Base) { 123 }
        end

        def comments
          # ActiveRecord::Base.comments
          # ::ActiveRecord::Base.comments
          # ActiveRecord.base.comments
          # ActiveRecord.comments
        end
      end
    RUBY
  end

  let(:code_with_correct_constants) do
    <<~RUBY
      class User < ApplicationRecord
        def connect
          ::ApplicationRecord.connection
        end

        def update
          ApplicationRecord.update
        end

        def create
          ActiveRecord.create
        end

        def classes
          Class.new(ApplicationRecord) { 123 }
        end

        def comments
          # ActiveRecord::Base.comments
          # ::ActiveRecord::Base.comments
          # ActiveRecord.base.comments
          # ActiveRecord.comments
        end
      end
    RUBY
  end

  it "registers offenses" do
    inspect_source(code_with_wrong_constants)

    aggregate_failures do
      expect(cop.offenses.size).to eq(4)
    end
  end

  it "registers no offenses" do
    inspect_source(code_with_correct_constants)

    aggregate_failures do
      expect(cop.offenses.size).to eq(0)
    end
  end

  it "autocorrects offenses" do
    autocorrected = autocorrect_source(code_with_wrong_constants)

    expect(autocorrected).to eq(code_with_correct_constants)
  end
end
