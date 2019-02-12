# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Authorize::Instrumentation do
  describe '#build_checker' do
    let(:current_user) { double(:current_user) }
    let(:abilities) { [double(:first_ability), double(:last_ability)] }

    let(:checker) do
      described_class.new.__send__(:build_checker, current_user, abilities)
    end

    it 'returns a checker which checks for a single object' do
      object = double(:object)

      abilities.each do |ability|
        spy_ability_check_for(ability, object)
      end

      expect(checker.call(object)).to eq(object)
    end

    it 'returns a checker which checks for all objects' do
      objects = [double(:first), double(:last)]

      abilities.each do |ability|
        objects.each do |object|
          spy_ability_check_for(ability, object)
        end
      end

      expect(checker.call(objects)).to eq(objects)
    end

    def spy_ability_check_for(ability, object)
      expect(Ability)
        .to receive(:allowed?)
        .with(current_user, ability, object)
        .and_return(true)
    end
  end
end
