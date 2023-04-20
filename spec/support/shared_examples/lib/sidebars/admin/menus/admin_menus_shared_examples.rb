# frozen_string_literal: true

RSpec.shared_examples 'Admin menu' do |link:, title:, icon:|
  let_it_be(:user) { build(:user, :admin) }

  before do
    allow(user).to receive(:can_admin_all_resources?).and_return(true)
  end

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

  it 'renders the correct link' do
    expect(subject.link).to match link
  end

  it 'renders the correct title' do
    expect(subject.title).to eq title
  end

  it 'renders the correct icon' do
    expect(subject.sprite_icon).to be icon
  end

  describe '#render?' do
    context 'when user is admin' do
      it 'renders' do
        expect(subject.render?).to be true
      end
    end

    context 'when user is not admin' do
      it 'does not render' do
        expect(described_class.new(Sidebars::Context.new(current_user: build(:user),
          container: nil)).render?).to be false
      end
    end

    context 'when user is not logged in' do
      it 'does not render' do
        expect(described_class.new(Sidebars::Context.new(current_user: nil, container: nil)).render?).to be false
      end
    end
  end
end

RSpec.shared_examples 'Admin menu without sub menus' do |active_routes:|
  let_it_be(:user) { build(:user, :admin) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

  it 'does not contain any sub menu(s)' do
    expect(subject.has_items?).to be false
  end

  it 'defines correct active route' do
    expect(subject.active_routes).to eq active_routes
  end
end

RSpec.shared_examples 'Admin menu with sub menus' do
  let_it_be(:user) { build(:user, :admin) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

  it 'contains submemus' do
    expect(subject.has_items?).to be true
  end
end
