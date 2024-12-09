# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'

require_relative '../../../../rubocop/feature_categories'
require_relative '../../../../rubocop/cop/rspec/feature_category'

RSpec.describe RuboCop::Cop::RSpec::FeatureCategory, feature_category: :tooling do
  shared_examples 'feature category validation' do |valid_category|
    it 'flags invalid feature category in top level example group' do
      expect_offense(<<~RUBY, invalid: invalid_category)
        RSpec.describe 'foo', feature_category: :%{invalid}, foo: :bar do
                                                ^^{invalid} Please use a valid feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples
        end
      RUBY
    end

    it 'flags invalid feature category in nested context' do
      expect_offense(<<~RUBY, valid: valid_category, invalid: invalid_category)
        RSpec.describe 'foo', feature_category: :"%{valid}" do
          context 'bar', foo: :bar, feature_category: :%{invalid} do
                                                      ^^{invalid} Please use a valid feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples
          end
        end
      RUBY
    end

    it 'flags invalid feature category in examples' do
      expect_offense(<<~RUBY, valid: valid_category, invalid: invalid_category)
        RSpec.describe 'foo', feature_category: :"%{valid}" do
          it 'bar', feature_category: :%{invalid} do
                                      ^^{invalid} Please use a valid feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples
          end
        end
      RUBY
    end

    it 'does not flag if feature category is valid' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe 'foo', feature_category: :"#{valid_category}" do
          context 'bar', feature_category: :"#{valid_category}" do
            it 'baz', feature_category: :"#{valid_category}" do
            end
          end
        end
      RUBY
    end

    it 'suggests an alternative' do
      mistyped = make_typo(valid_category)

      expect_offense(<<~RUBY, invalid: mistyped, valid: valid_category)
        RSpec.describe 'foo', feature_category: :"%{invalid}" do
                                                ^^^^{invalid} Please use a valid feature category. Did you mean `:%{valid}`? See [...]
        end
      RUBY
    end

    def make_typo(string)
      "#{string}#{string[-1]}"
    end
  end

  let(:invalid_category) { :invalid_category }

  context 'with defined in config/feature_categories.yml and custom categories' do
    where(:valid_category) { RuboCop::FeatureCategories.available_with_custom.to_a }

    with_them do
      it_behaves_like 'feature category validation', params[:valid_category]
    end
  end

  it 'flags invalid feature category for non-symbols' do
    expect_offense(<<~RUBY, invalid: invalid_category)
      RSpec.describe 'foo', feature_category: "%{invalid}" do
                                              ^^^{invalid} Please use a symbol as value.
      end

      RSpec.describe 'foo', feature_category: 42 do
                                              ^^ Please use a symbol as value.
      end
    RUBY
  end

  it 'does not flag use of invalid categories in non-example code' do
    valid_category = RuboCop::FeatureCategories.available.first

    # See https://gitlab.com/gitlab-org/gitlab/-/issues/381882#note_1265865125
    expect_no_offenses(<<~RUBY)
      RSpec.describe 'A spec', feature_category: :#{valid_category} do
        let(:api_handler) do
          Class.new(described_class) do
            namespace '/test' do
              get 'hello', feature_category: :foo, urgency: :#{invalid_category} do
              end
            end
          end
        end

        it 'tests something' do
          Gitlab::ApplicationContext.with_context(feature_category: :#{invalid_category}) do
            payload = generator.generate(exception, extra)
          end
        end
      end
    RUBY
  end

  it 'flags missing feature category in top level example group' do
    expect_offense(<<~RUBY)
      RSpec.describe 'foo' do
      ^^^^^^^^^^^^^^^^^^^^ Please use a valid feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples
      end

      RSpec.describe 'foo', some: :tag do
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Please use a valid feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples
      end
    RUBY
  end

  describe '#external_dependency_checksum' do
    it 'returns a SHA256 digest used by RuboCop to invalid cache' do
      expect(cop.external_dependency_checksum).to match(/^\h{64}$/)
    end
  end
end
