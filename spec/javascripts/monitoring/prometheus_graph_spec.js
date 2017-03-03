import '~/lib/utils/common_utils.js.es6';
import PrometheusGraph from '~/monitoring/prometheus_graph';
import { prometheusMockData } from './prometheus_mock_data';

require('es6-promise').polyfill();

fdescribe('PrometheusGraph', () => {
  const fixtureName = 'static/environments/metrics.html.raw';
  // let promiseHelper = {};
  // let getDataPromise = {};

  preloadFixtures(fixtureName);

  beforeEach(() => {
    loadFixtures(fixtureName);
    this.prometheusGraph = new PrometheusGraph();

    this.ajaxSpy = spyOn($, 'ajax').and.callFake((req) => {
      req.success(prometheusMockData);
    });

    // const fetchPromise = new Promise((res, rej) => {
    //   promiseHelper = {
    //     resolve: res,
    //     reject: rej,
    //   };
    // });

    // spyOn(this.prometheusGraph, 'getData').and.returnValue(fetchPromise);
    // getDataPromise = this.prometheusGraph.getData();
    spyOn(gl.utils, 'backOff').and.callFake(() => {
      const promise = new Promise();
      promise.resolve(prometheusMockData.metrics);
      return promise;
    });
  });

  it('initializes graph properties', () => {
    // Test for the measurements
    expect(this.prometheusGraph.margin).toBeDefined();
    expect(this.prometheusGraph.marginLabelContainer).toBeDefined();
    expect(this.prometheusGraph.originalWidth).toBeDefined();
    expect(this.prometheusGraph.originalHeight).toBeDefined();
    expect(this.prometheusGraph.height).toBeDefined();
    expect(this.prometheusGraph.width).toBeDefined();
    expect(this.prometheusGraph.backOffRequestCounter).toBeDefined();
    // Test for the graph properties (colors, radius, etc.)
    expect(this.prometheusGraph.graphSpecificProperties).toBeDefined();
    expect(this.prometheusGraph.commonGraphProperties).toBeDefined();
  });

  it('getData should be called', () => {
  });



  // describe('fetches the data from the prometheus integration', () => {
  //   beforeEach((done) => {
  //     promiseHelper.resolve(prometheusMockData.metrics);
  //     done();
  //   });

  //   it('calls the getData method', () => {
  //     expect(this.prometheusGraph.getData).toHaveBeenCalled();
  //   });

  //   it('resolves the getData promise', (done) => {
  //     getDataPromise.then((metricsResponse) => {
  //       expect(metricsResponse).toBeDefined();
  //       done();
  //     });
  //   });

  //   it('transforms the data after fetch', () => {
  //     getDataPromise.then((metricsResponse) => {
  //       this.transformData(metricsResponse.metrics);
  //       expect(this.data).toBeDefined();
  //     });
  //   });
  // });
});
