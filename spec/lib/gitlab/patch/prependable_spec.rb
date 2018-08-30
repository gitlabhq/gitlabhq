# frozen_string_literal: true

require 'fast_spec_helper'

# Patching ActiveSupport::Concern
require_relative '../../../../config/initializers/0_as_concern'

describe Gitlab::Patch::Prependable do
  let(:prepended_modules) { [] }

  let(:ee) do
    # So that block in Module.new could see them
    prepended_modules_ = prepended_modules

    Module.new do
      extend ActiveSupport::Concern

      class_methods do
        def class_name
          super.tr('C', 'E')
        end
      end

      this = self
      prepended do
        prepended_modules_ << this
      end

      def name
        super.tr('c', 'e')
      end
    end
  end

  let(:ce) do
    prepended_modules_ = prepended_modules
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
        prepended_modules_ << this
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

    it 'prepends only once' do
      ce.prepend(ee)
      ce.prepend(ee)

      subject

      expect(prepended_modules).to eq([ee, ce])
    end
  end

  describe 'a class prepending a concern prepending a concern' do
    subject { Class.new.prepend(ce) }

    it 'returns values from prepended module ce' do
      expect(subject.new.name).to eq('ce')
      expect(subject.class_name).to eq('CE')
    end

    it 'prepends only once' do
      subject.prepend(ce)

      expect(prepended_modules).to eq([ee, ce])
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

    it 'prepends only once' do
      subject.prepend(ee)

      expect(prepended_modules).to eq([ee])
    end
  end
end
