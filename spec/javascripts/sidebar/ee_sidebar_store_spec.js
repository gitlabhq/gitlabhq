import SidebarStore from 'ee/sidebar/stores/sidebar_store';

describe('EE Sidebar store', () => {
  beforeEach(() => {
    this.store = new SidebarStore({
      weightOptions: ['No Weight', 0, 1, 3],
      weightNoneValue: 'No Weight',
    });
  });

  afterEach(() => {
    SidebarStore.singleton = null;
  });

  it('sets weight data', () => {
    expect(this.store.weight).toEqual(null);

    const weight = 3;
    this.store.setWeightData({
      weight,
    });

    expect(this.store.isFetching.weight).toEqual(false);
    expect(this.store.weight).toEqual(weight);
  });

  it('set weight', () => {
    const weight = 3;
    this.store.setWeight(weight);

    expect(this.store.weight).toEqual(weight);
  });
});
