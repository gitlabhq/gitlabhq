import KubernetesLogs from 'ee/kubernetes_logs';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { logMockData } from './ee/kubernetes_mock_data';

describe('Kubernetes Logs', () => {
  const fixtureTemplate = 'static/environments_logs.html.raw';
  const mockPodName = 'production-tanuki-1';
  const logMockPath = '/root/kubernetes-app/environments/1/logs';
  let kubernetesLogContainer;
  let kubernetesLog;
  let mock;
  preloadFixtures(fixtureTemplate);

  describe('When data is requested correctly', () => {
    beforeEach(() => {
      loadFixtures(fixtureTemplate);

      spyOnDependency(KubernetesLogs, 'getParameterValues').and.callFake(() => [mockPodName]);

      mock = new MockAdapter(axios);

      mock.onGet(logMockPath).reply(200, { logs: logMockData });

      kubernetesLogContainer = document.querySelector('.js-kubernetes-logs');
    });

    afterEach(() => {
      mock.restore();
    });

    it('has the pod name placed on the top bar', () => {
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);
      const topBar = document.querySelector('.js-pod-name');

      expect(topBar.textContent).toContain(kubernetesLog.podName);
    });

    it('queries the pod log data and sets the dom elements', (done) => {
      const scrollSpy = spyOnDependency(KubernetesLogs, 'scrollDown').and.callThrough();
      const toggleDisableSpy = spyOnDependency(KubernetesLogs, 'toggleDisableButton').and.stub();
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);

      kubernetesLog.getPodLogs();
      setTimeout(() => {
        expect(kubernetesLog.isLogComplete).toEqual(true);
        expect(kubernetesLog.$buildOutputContainer.text()).toContain(logMockData[0].trim());
        expect(scrollSpy).toHaveBeenCalled();
        expect(toggleDisableSpy).toHaveBeenCalled();
        done();
      }, 0);
    });
  });

  describe('When no pod name is available', () => {
    beforeEach(() => {
      loadFixtures(fixtureTemplate);

      kubernetesLogContainer = document.querySelector('.js-kubernetes-logs');
    });

    it('shows up a flash message when no pod name is specified', () => {
      const createFlashSpy = spyOnDependency(KubernetesLogs, 'createFlash').and.stub();
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);

      expect(createFlashSpy).toHaveBeenCalled();
    });
  });
});
