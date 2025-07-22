# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/use_class_name_converter'

RSpec.describe RuboCop::Cop::Gitlab::UseClassNameConverter, :config, feature_category: :shared do
  describe 'offense detection' do
    it 'registers an offense for name.underscore.tr pattern' do
      expect_offense(<<~RUBY)
        class Example
          def class_name
            self.name.underscore.tr('/', '_')
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `::Gitlab::Utils::ClassNameConverter.new(self).string_representation` instead of `self.name.underscore.tr('/', '_')`.
          end
        end
      RUBY
    end

    it 'registers an offense for class name pattern' do
      expect_offense(<<~RUBY)
        class Example
          def class_name
            self.class.name.underscore.tr('/', '_')
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `::Gitlab::Utils::ClassNameConverter.new(self.class).string_representation` instead of `self.class.name.underscore.tr('/', '_')`.
          end
        end
      RUBY
    end

    it 'registers an offense for variable name pattern' do
      expect_offense(<<~RUBY)
        def example
          klass = SomeClass
          klass.name.underscore.tr('/', '_')
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `::Gitlab::Utils::ClassNameConverter.new(klass).string_representation` instead of `klass.name.underscore.tr('/', '_')`.
        end
      RUBY
    end

    it 'registers an offense for method call name pattern' do
      expect_offense(<<~RUBY)
        def example
          get_class.name.underscore.tr('/', '_')
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `::Gitlab::Utils::ClassNameConverter.new(get_class).string_representation` instead of `get_class.name.underscore.tr('/', '_')`.
        end
      RUBY
    end

    it 'registers an offense for constant name pattern' do
      expect_offense(<<~RUBY)
        def example
          MyClass.name.underscore.tr('/', '_')
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `::Gitlab::Utils::ClassNameConverter.new(MyClass).string_representation` instead of `MyClass.name.underscore.tr('/', '_')`.
        end
      RUBY
    end
  end

  describe 'no offense cases' do
    it 'does not register an offense for different tr arguments' do
      expect_no_offenses(<<~RUBY)
        class Example
          def class_name
            self.name.underscore.tr('-', '_')
          end
        end
      RUBY
    end

    it 'does not register an offense for different tr replacement' do
      expect_no_offenses(<<~RUBY)
        class Example
          def class_name
            self.name.underscore.tr('/', '-')
          end
        end
      RUBY
    end

    it 'does not register an offense for missing underscore call' do
      expect_no_offenses(<<~RUBY)
        class Example
          def class_name
            self.name.tr('/', '_')
          end
        end
      RUBY
    end

    it 'does not register an offense for missing name call' do
      expect_no_offenses(<<~RUBY)
        class Example
          def class_name
            self.underscore.tr('/', '_')
          end
        end
      RUBY
    end

    it 'does not register an offense for different method chain' do
      expect_no_offenses(<<~RUBY)
        class Example
          def class_name
            self.to_s.underscore.tr('/', '_')
          end
        end
      RUBY
    end

    it 'does not register an offense for partial pattern' do
      expect_no_offenses(<<~RUBY)
        class Example
          def class_name
            something.tr('/', '_')
          end
        end
      RUBY
    end

    it 'does not register an offense for already converted code' do
      expect_no_offenses(<<~RUBY)
        class Example
          def class_name
            ::Gitlab::Utils::ClassNameConverter.new(self).string_representation
          end
        end
      RUBY
    end

    it 'does not register an offense for safe navigation operator' do
      expect_no_offenses(<<~RUBY)
        class Example
          def class_name
            obj&.name.underscore.tr('/', '_')
          end
        end
      RUBY
    end
  end

  describe 'auto-correction' do
    it 'corrects name.underscore.tr pattern with self' do
      expect_offense(<<~RUBY)
        class Example
          def class_name
            self.name.underscore.tr('/', '_')
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `::Gitlab::Utils::ClassNameConverter.new(self).string_representation` instead of `self.name.underscore.tr('/', '_')`.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Example
          def class_name
            ::Gitlab::Utils::ClassNameConverter.new(self).string_representation
          end
        end
      RUBY
    end

    it 'corrects name.underscore.tr pattern with class' do
      expect_offense(<<~RUBY)
        class Example
          def class_name
            self.class.name.underscore.tr('/', '_')
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `::Gitlab::Utils::ClassNameConverter.new(self.class).string_representation` instead of `self.class.name.underscore.tr('/', '_')`.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Example
          def class_name
            ::Gitlab::Utils::ClassNameConverter.new(self.class).string_representation
          end
        end
      RUBY
    end

    it 'corrects name.underscore.tr pattern with variable' do
      expect_offense(<<~RUBY)
        def example
          klass = SomeClass
          klass.name.underscore.tr('/', '_')
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `::Gitlab::Utils::ClassNameConverter.new(klass).string_representation` instead of `klass.name.underscore.tr('/', '_')`.
        end
      RUBY

      expect_correction(<<~RUBY)
        def example
          klass = SomeClass
          ::Gitlab::Utils::ClassNameConverter.new(klass).string_representation
        end
      RUBY
    end

    it 'corrects name.underscore.tr pattern with method call' do
      expect_offense(<<~RUBY)
        def example
          get_class.name.underscore.tr('/', '_')
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `::Gitlab::Utils::ClassNameConverter.new(get_class).string_representation` instead of `get_class.name.underscore.tr('/', '_')`.
        end
      RUBY

      expect_correction(<<~RUBY)
        def example
          ::Gitlab::Utils::ClassNameConverter.new(get_class).string_representation
        end
      RUBY
    end

    it 'corrects name.underscore.tr pattern with constant' do
      expect_offense(<<~RUBY)
        def example
          MyClass.name.underscore.tr('/', '_')
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `::Gitlab::Utils::ClassNameConverter.new(MyClass).string_representation` instead of `MyClass.name.underscore.tr('/', '_')`.
        end
      RUBY

      expect_correction(<<~RUBY)
        def example
          ::Gitlab::Utils::ClassNameConverter.new(MyClass).string_representation
        end
      RUBY
    end
  end
end
