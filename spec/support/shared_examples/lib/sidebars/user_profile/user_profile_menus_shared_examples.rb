# frozen_string_literal: true

RSpec.shared_examples 'User profile menu' do |
  icon:, active_route:, avatar_shape: 'rect', expect_avatar: false, entity_id: nil,
  # A nil title will fall back to user.name.
  title: nil
|
  let_it_be(:current_user) { build(:user) }
  let_it_be(:user) { build(:user) }

  let(:context) { Sidebars::Context.new(current_user: current_user, container: user) }

  subject { described_class.new(context) }

  it 'does not contain any sub menu' do
    expect(subject.has_items?).to be false
  end

  it 'renders the correct link' do
    expect(subject.link).to match link
  end

  it 'renders the correct title' do
    expect(subject.title).to eq(title || user.name)
  end

  it 'renders the correct icon' do
    expect(subject.sprite_icon).to eq icon
  end

  it 'renders the correct avatar' do
    expect(subject.avatar).to eq(expect_avatar ? user.avatar_url : nil)
    expect(subject.avatar_shape).to eq(avatar_shape)
    expect(subject.entity_id).to eq(entity_id)
  end

  it 'defines correct active route' do
    expect(subject.active_routes[:path]).to be active_route
  end

  it 'renders if user is logged in' do
    expect(subject.render?).to be true
  end

  [:blocked, :banned].each do |trait|
    context "when viewed user is #{trait}" do
      let_it_be(:viewed_user) { build(:user, trait) }
      let(:context) { Sidebars::Context.new(current_user: user, container: viewed_user) }

      context 'when user is not logged in' do
        it 'is not allowed to view the menu item' do
          expect(described_class.new(Sidebars::Context.new(current_user: nil,
            container: viewed_user)).render?).to be false
        end
      end

      context 'when current user has permission' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :read_user_profile, viewed_user).and_return(true)
        end

        it 'is allowed to view the menu item' do
          expect(described_class.new(context).render?).to be true
        end
      end

      context 'when current user does not have permission' do
        it 'is not allowed to view the menu item' do
          expect(described_class.new(context).render?).to be false
        end
      end
    end
  end
end

RSpec.shared_examples 'Followers/followees counts' do |symbol|
  let_it_be(:current_user) { build(:user) }
  let_it_be(:user) { build(:user) }

  let(:context) { Sidebars::Context.new(current_user: current_user, container: user) }

  subject { described_class.new(context) }

  context 'when there are items' do
    before do
      allow(user).to receive(symbol).and_return([1, 2])
    end

    it 'renders the pill' do
      expect(subject.has_pill?).to be(true)
    end

    it 'returns the count' do
      expect(subject.pill_count).to be(2)
    end
  end

  context 'when there are no items' do
    it 'does not render the pill' do
      expect(subject.has_pill?).to be(false)
    end
  end
end
