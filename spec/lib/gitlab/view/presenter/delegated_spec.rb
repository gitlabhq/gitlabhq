# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::View::Presenter::Delegated do
  let(:project) { double(:project, user: 'John Doe') }
  let(:presenter_class) do
    Class.new(described_class)
  end

  it 'includes Gitlab::View::Presenter::Base' do
    expect(described_class).to include(Gitlab::View::Presenter::Base)
  end

  describe '#initialize' do
    it 'takes arbitrary key/values and exposes them' do
      presenter = presenter_class.new(project, current_user: 'Jane Doe')

      expect(presenter.current_user).to eq('Jane Doe')
    end

    it 'raise an error if the presentee already respond to method' do
      expect { presenter_class.new(project, user: 'Jane Doe') }
        .to raise_error Gitlab::View::Presenter::CannotOverrideMethodError
    end
  end

  describe 'delegation' do
    it 'forwards missing methods to subject' do
      presenter = presenter_class.new(project)

      expect(presenter.user).to eq('John Doe')
    end
  end
end
