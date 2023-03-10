# frozen_string_literal: true

RSpec.shared_examples 'User settings menu' do |link:, title:, icon:, active_routes:|
  let_it_be(:user) { create(:user) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

  it 'does not contain any sub menu' do
    expect(subject.has_items?).to be false
  end

  it 'renders the correct link' do
    expect(subject.link).to match link
  end

  it 'renders the correct title' do
    expect(subject.title).to eq title
  end

  it 'renders the correct icon' do
    expect(subject.sprite_icon).to be icon
  end

  it 'defines correct active route' do
    expect(subject.active_routes).to eq active_routes
  end
end

RSpec.shared_examples 'User settings menu #render? method' do
  describe '#render?' do
    subject { described_class.new(context) }

    context 'when user is logged in' do
      let_it_be(:user) { build(:user) }
      let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

      it 'renders' do
        expect(subject.render?).to be true
      end
    end

    context 'when user is not logged in' do
      let(:context) { Sidebars::Context.new(current_user: nil, container: nil) }

      it 'does not render' do
        expect(subject.render?).to be false
      end
    end
  end
end
