# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::View::Presenter::Simple do
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

    it 'override the presentee attributes' do
      presenter = presenter_class.new(project, user: 'Jane Doe')

      expect(presenter.user).to eq('Jane Doe')
    end
  end

  describe 'delegation' do
    it 'does not forward missing methods to subject' do
      presenter = presenter_class.new(project)

      expect { presenter.user }.to raise_error(NoMethodError)
    end
  end
end
