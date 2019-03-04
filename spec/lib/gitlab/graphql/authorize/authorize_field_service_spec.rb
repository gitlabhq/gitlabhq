# frozen_string_literal: true

require 'spec_helper'

# Also see spec/graphql/features/authorization_spec.rb for
# integration tests of AuthorizeFieldService
describe Gitlab::Graphql::Authorize::AuthorizeFieldService do
  describe '#build_checker' do
    let(:current_user) { double(:current_user) }
    let(:abilities) { [double(:first_ability), double(:last_ability)] }

    let(:checker) do
      service = described_class.new(double(resolve_proc: proc {}))
      allow(service).to receive(:authorizations).and_return(abilities)
      service.__send__(:build_checker, current_user)
    end

    it 'returns a checker which checks for a single object' do
      object = double(:object)

      abilities.each do |ability|
        spy_ability_check_for(ability, object, passed: true)
      end

      expect(checker.call(object)).to eq(object)
    end

    it 'returns a checker which checks for all objects' do
      objects = [double(:first), double(:last)]

      abilities.each do |ability|
        objects.each do |object|
          spy_ability_check_for(ability, object, passed: true)
        end
      end

      expect(checker.call(objects)).to eq(objects)
    end

    context 'when some objects would not pass the check' do
      it 'returns nil when it is single object' do
        disallowed = double(:object)

        spy_ability_check_for(abilities.first, disallowed, passed: false)

        expect(checker.call(disallowed)).to be_nil
      end

      it 'returns only objects which passed when there are more than one' do
        allowed = double(:allowed)
        disallowed = double(:disallowed)

        spy_ability_check_for(abilities.first, disallowed, passed: false)

        abilities.each do |ability|
          spy_ability_check_for(ability, allowed, passed: true)
        end

        expect(checker.call([disallowed, allowed]))
          .to contain_exactly(allowed)
      end
    end
  end

  private

  def spy_ability_check_for(ability, object, passed: true)
    expect(Ability)
      .to receive(:allowed?)
      .with(current_user, ability, object)
      .and_return(passed)
  end
end
