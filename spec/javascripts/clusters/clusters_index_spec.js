import ClusterTable from '~/clusters/clusters_index';

describe('Clusters table', () => {
  let ClustersClass;

  beforeEach(() => {
    ClustersClass = new ClusterTable();
  });

  afterEach(() => {
    ClustersClass.removeListeners();
  });

  describe('update cluster', () => {
    it('renders a toggle button', () => {

    });

    it('renders loading state while request is made', () => {

    });

    it('shows updated state after sucessfull request', () => {

    });

    it('shows inital state after failed request', () => {

    });
  });
});
