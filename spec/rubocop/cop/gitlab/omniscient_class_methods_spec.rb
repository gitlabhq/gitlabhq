# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/omniscient_class_methods'

RSpec.describe RuboCop::Cop::Gitlab::OmniscientClassMethods, feature_category: :tooling do
  let(:baseline) do
    {
      'Project' => Set['intrinsic_method', 'existing_method', 'self.existing_class_method'],
      'EE::Project' => Set['existing_method', 'self.existing_class_method']
    }
  end

  before do
    allow(described_class).to receive(:baseline).and_return(baseline)
  end

  it 'registers an offense for a new instance method' do
    expect_offense(<<~RUBY)
      class Project < ApplicationRecord
        def self.existing_class_method; end
        def intrinsic_method; end
        def existing_method; end

        def new_method
            ^^^^^^^^^^ Do not add methods to omniscient classes like `Project`. [...]
        end
      end
    RUBY
  end

  it 'registers an offense for new class methods' do
    expect_offense(<<~RUBY)
      class Project < ApplicationRecord
        def self.existing_class_method; end
        def intrinsic_method; end
        def existing_method; end

        def self.new_class_method; end
                 ^^^^^^^^^^^^^^^^ Do not add methods to omniscient classes like `Project`. [...]

        class << self
          def other_class_method; end
              ^^^^^^^^^^^^^^^^^^ Do not add methods to omniscient classes like `Project`. [...]
        end
      end
    RUBY
  end

  it 'registers an offense when an instance method reuses a class method name' do
    expect_offense(<<~RUBY)
      class Project < ApplicationRecord
        def self.existing_class_method; end
        def intrinsic_method; end
        def existing_method; end
        def existing_class_method; end
            ^^^^^^^^^^^^^^^^^^^^^ Do not add methods to omniscient classes like `Project`. [...]
      end
    RUBY
  end

  it 'registers an offense for new methods in EE modules' do
    expect_offense(<<~RUBY)
      module EE
        module Project
          prepended do
            def existing_method; end
          end

          class_methods do
            def existing_class_method; end
            def new_class_method; end
                ^^^^^^^^^^^^^^^^ Do not add methods to omniscient classes like `EE::Project`. [...]
          end
        end
      end
    RUBY
  end

  it 'does not register an offense for methods of nested modules' do
    expect_no_offenses(<<~RUBY)
      module EE
        module Project
          module FilterByBranch
            def new_method; end
          end

          def existing_method; end
          def self.existing_class_method; end
        end
      end
    RUBY
  end

  it 'does not register an offense for classes not in the baseline' do
    expect_no_offenses(<<~RUBY)
      class Issue < ApplicationRecord
        def new_method; end
      end
    RUBY
  end

  it 'does not register an offense for methods defined on another receiver' do
    expect_no_offenses(<<~RUBY)
      class Project < ApplicationRecord
        def Foo.new_method; end
      end
    RUBY
  end

  it 'does not register an offense for methods outside a class or module' do
    expect_no_offenses(<<~RUBY)
      def new_method; end
    RUBY
  end

  it 'registers an offense for baseline methods that the class no longer defines' do
    expect_offense(<<~RUBY)
      class Project < ApplicationRecord
            ^^^^^^^ Remove methods that `Project` no longer defines from rubocop/cop/gitlab/config/omniscient_classes_baseline.yml: existing_method, self.existing_class_method
        def intrinsic_method; end
      end
    RUBY
  end

  describe '.baseline' do
    before do
      allow(described_class).to receive(:baseline).and_call_original
    end

    it 'loads intrinsic and legacy methods for each class' do
      expect(described_class.baseline.keys)
        .to contain_exactly('Project', 'EE::Project', 'Group', 'EE::Group', 'User', 'EE::User')
      expect(described_class.baseline.values).to all(be_a(Set).and(all(be_a(String))))
    end
  end

  describe '.external_dependency_checksum' do
    it 'returns a SHA256 hex digest of the baseline file' do
      expect(described_class.external_dependency_checksum).to match(/\A[a-f0-9]{64}\z/)
    end
  end

  describe '#external_dependency_checksum' do
    it 'delegates to the class method' do
      expect(cop.external_dependency_checksum).to eq(described_class.external_dependency_checksum)
    end
  end
end
