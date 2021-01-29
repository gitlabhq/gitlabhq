# frozen_string_literal: true

require 'fast_spec_helper'

# Patching ActiveSupport::Concern
require_relative '../../../../config/initializers/0_as_concern'

RSpec.describe Gitlab::Patch::Prependable do
  before do
    @prepended_modules = []
  end

  let(:ee) do
    # So that block in Module.new could see them
    prepended_modules = @prepended_modules

    Module.new do
      extend ActiveSupport::Concern

      class_methods do
        def class_name
          super.tr('C', 'E')
        end
      end

      this = self
      prepended do
        prepended_modules << [self, this]
      end

      def name
        super.tr('c', 'e')
      end
    end
  end

  let(:ce) do
    # So that block in Module.new could see them
    prepended_modules = @prepended_modules
    ee_ = ee

    Module.new do
      extend ActiveSupport::Concern
      prepend ee_

      class_methods do
        def class_name
          'CE'
        end
      end

      this = self
      prepended do
        prepended_modules << [self, this]
      end

      def name
        'ce'
      end
    end
  end

  describe 'a class including a concern prepending a concern' do
    subject { Class.new.include(ce) }

    it 'returns values from prepended module ee' do
      expect(subject.new.name).to eq('ee')
      expect(subject.class_name).to eq('EE')
    end

    it 'has the expected ancestors' do
      expect(subject.ancestors.take(3)).to eq([subject, ee, ce])
      expect(subject.singleton_class.ancestors.take(3))
        .to eq([subject.singleton_class,
                ee.const_get(:ClassMethods, false),
                ce.const_get(:ClassMethods, false)])
    end

    it 'prepends only once even if called twice' do
      2.times { ce.prepend(ee) }

      subject

      expect(@prepended_modules).to eq([[ce, ee]])
    end

    context 'overriding methods' do
      before do
        subject.module_eval do
          def self.class_name
            'Custom'
          end

          def name
            'custom'
          end
        end
      end

      it 'returns values from the class' do
        expect(subject.new.name).to eq('custom')
        expect(subject.class_name).to eq('Custom')
      end
    end
  end

  describe 'a class prepending a concern prepending a concern' do
    subject { Class.new.prepend(ce) }

    it 'returns values from prepended module ee' do
      expect(subject.new.name).to eq('ee')
      expect(subject.class_name).to eq('EE')
    end

    it 'has the expected ancestors' do
      expect(subject.ancestors.take(3)).to eq([ee, ce, subject])
      expect(subject.singleton_class.ancestors.take(3))
        .to eq([ee.const_get(:ClassMethods, false),
                ce.const_get(:ClassMethods, false),
                subject.singleton_class])
    end

    it 'prepends only once' do
      subject.prepend(ce)

      expect(@prepended_modules).to eq([[ce, ee], [subject, ce]])
    end
  end

  describe 'a class prepending a concern' do
    subject do
      ee_ = ee

      Class.new do
        prepend ee_

        def self.class_name
          'CE'
        end

        def name
          'ce'
        end
      end
    end

    it 'returns values from prepended module ee' do
      expect(subject.new.name).to eq('ee')
      expect(subject.class_name).to eq('EE')
    end

    it 'has the expected ancestors' do
      expect(subject.ancestors.take(2)).to eq([ee, subject])
      expect(subject.singleton_class.ancestors.take(2))
        .to eq([ee.const_get(:ClassMethods, false),
                subject.singleton_class])
    end

    it 'prepends only once' do
      subject.prepend(ee)

      expect(@prepended_modules).to eq([[subject, ee]])
    end
  end

  describe 'simple case' do
    subject do
      foo_ = foo

      Class.new do
        prepend foo_

        def value
          10
        end
      end
    end

    let(:foo) do
      Module.new do
        extend ActiveSupport::Concern

        prepended do
          def self.class_value
            20
          end
        end

        def value
          super * 10
        end
      end
    end

    context 'class methods' do
      it "has a method" do
        expect(subject).to respond_to(:class_value)
      end

      it 'can execute a method' do
        expect(subject.class_value).to eq(20)
      end
    end

    context 'instance methods' do
      it "has a method" do
        expect(subject.new).to respond_to(:value)
      end

      it 'chains a method execution' do
        expect(subject.new.value).to eq(100)
      end
    end
  end

  context 'having two prepended blocks' do
    subject do
      Module.new do
        extend ActiveSupport::Concern

        prepended do
        end

        prepended do
        end
      end
    end

    it "raises an error" do
      expect { subject }
        .to raise_error(described_class::MultiplePrependedBlocks)
    end
  end

  describe 'the extra hack for override verification' do
    context 'when ENV["STATIC_VERIFICATION"] is not defined' do
      it 'does not extend ClassMethods onto the defining module' do
        expect(ee).not_to respond_to(:class_name)
      end
    end

    context 'when ENV["STATIC_VERIFICATION"] is defined' do
      before do
        stub_env('STATIC_VERIFICATION', 'true')
      end

      it 'does extend ClassMethods onto the defining module' do
        expect(ee).to respond_to(:class_name)
      end
    end
  end
end
