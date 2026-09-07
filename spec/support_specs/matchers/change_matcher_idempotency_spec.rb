# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../support/matchers/change_idempotently'

RSpec.describe ChangeMatcherIdempotency, feature_category: :tooling do
  let(:store) { [] }

  def idempotent_insert
    store << :item unless store.include?(:item)
  end

  def non_idempotent_insert
    store << :item
  end

  it 'passes when the second run leaves the value alone' do
    expect { idempotent_insert }.to change { store.size }.by(1).idempotently
  end

  it 'fails when the second run changes the value' do
    expect { expect { non_idempotent_insert }.to change { store.size }.by(1).idempotently }
      .to raise_error(
        RSpec::Expectations::ExpectationNotMetError,
        /not to have changed on the second run, but did change from 1 to 2/
      )
  end

  it 'keeps the original failure message when the first run does not match' do
    expect { expect { idempotent_insert }.to change { store.size }.by(2).idempotently }
      .to raise_error(
        RSpec::Expectations::ExpectationNotMetError,
        /to have changed by 2, but was changed by 1/
      )
  end

  it 'works without a chain' do
    expect { idempotent_insert }.to change { store.size }.idempotently
  end

  shared_examples_for 'working with chains' do |chain, chain_arg|
    it "works before a `#{chain}` chain" do
      expect { idempotent_insert }.to change { store.size }.idempotently.public_send(chain, chain_arg)
    end

    it 'works after a `by` chain' do
      expect { idempotent_insert }.to change { store.size }.public_send(chain, chain_arg).idempotently
    end
  end

  it_behaves_like 'working with chains', :by, 1
  it_behaves_like 'working with chains', :by_at_least, 1
  it_behaves_like 'working with chains', :by_at_most, 1
  it_behaves_like 'working with chains', :from, 0
  it_behaves_like 'working with chains', :to, 1

  it 'works with the receiver and message form' do
    # rubocop:disable RSpec/ExpectChange -- the receiver and message form is what this example covers
    expect { idempotent_insert }.to change(store, :size).by(1).idempotently
    # rubocop:enable RSpec/ExpectChange
  end

  it 'is not supported with `not_to`' do
    expect { expect { idempotent_insert }.not_to change { store.size }.idempotently }
      .to raise_error(NotImplementedError, /not_to change/)
  end

  it 'mentions idempotency in the description' do
    expect(change { store.size }.by(1).idempotently.description).to end_with('by 1 idempotently')
  end

  it 'leaves the plain matcher alone' do
    runs = 0

    expect { runs += 1 }.to change { runs }.by(1)

    expect(runs).to eq(1)
  end
end
