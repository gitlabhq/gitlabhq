import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import renderNotebook from '~/blob/notebook';

describe('iPython notebook renderer', () => {
  preloadFixtures('static/notebook_viewer.html.raw');

  beforeEach(() => {
    loadFixtures('static/notebook_viewer.html.raw');
  });

  it('shows loading icon', () => {
    renderNotebook();

    expect(
      document.querySelector('.loading'),
    ).not.toBeNull();
  });

  describe('successful response', () => {
    let mock;

    beforeEach((done) => {
      mock = new MockAdapter(axios);
      mock.onGet('/test').reply(200, {
        cells: [{
          cell_type: 'markdown',
          source: ['# test'],
        }, {
          cell_type: 'code',
          execution_count: 1,
          source: [
            'def test(str)',
            '  return str',
          ],
          outputs: [],
        }],
      });

      renderNotebook();

      setTimeout(() => {
        done();
      });
    });

    afterEach(() => {
      mock.restore();
    });

    it('does not show loading icon', () => {
      expect(
        document.querySelector('.loading'),
      ).toBeNull();
    });

    it('renders the notebook', () => {
      expect(
        document.querySelector('.md'),
      ).not.toBeNull();
    });

    it('renders the markdown cell', () => {
      expect(
        document.querySelector('h1'),
      ).not.toBeNull();

      expect(
        document.querySelector('h1').textContent.trim(),
      ).toBe('test');
    });

    it('highlights code', () => {
      expect(
        document.querySelector('.token'),
      ).not.toBeNull();

      expect(
        document.querySelector('.language-python'),
      ).not.toBeNull();
    });
  });

  describe('error in JSON response', () => {
    let mock;

    beforeEach((done) => {
      mock = new MockAdapter(axios);
      mock.onGet('/test').reply(() => Promise.reject({ status: 200, data: '{ "cells": [{"cell_type": "markdown"} }' }));

      renderNotebook();

      setTimeout(() => {
        done();
      });
    });

    afterEach(() => {
      mock.restore();
    });

    it('does not show loading icon', () => {
      expect(
        document.querySelector('.loading'),
      ).toBeNull();
    });

    it('shows error message', () => {
      expect(
        document.querySelector('.md').textContent.trim(),
      ).toBe('An error occurred whilst parsing the file.');
    });
  });

  describe('error getting file', () => {
    let mock;

    beforeEach((done) => {
      mock = new MockAdapter(axios);
      mock.onGet('/test').reply(500, '');

      renderNotebook();

      setTimeout(() => {
        done();
      });
    });

    afterEach(() => {
      mock.restore();
    });

    it('does not show loading icon', () => {
      expect(
        document.querySelector('.loading'),
      ).toBeNull();
    });

    it('shows error message', () => {
      expect(
        document.querySelector('.md').textContent.trim(),
      ).toBe('An error occurred whilst loading the file. Please try again later.');
    });
  });
});
