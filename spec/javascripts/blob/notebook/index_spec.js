import Vue from 'vue';
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
    const response = (request, next) => {
      next(request.respondWith(JSON.stringify({
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
      }), {
        status: 200,
      }));
    };

    beforeEach((done) => {
      Vue.http.interceptors.push(response);

      renderNotebook();

      setTimeout(() => {
        done();
      });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, response,
      );
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
    const response = (request, next) => {
      next(request.respondWith('{ "cells": [{"cell_type": "markdown"} }', {
        status: 200,
      }));
    };

    beforeEach((done) => {
      Vue.http.interceptors.push(response);

      renderNotebook();

      setTimeout(() => {
        done();
      });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, response,
      );
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
    const response = (request, next) => {
      next(request.respondWith('', {
        status: 500,
      }));
    };

    beforeEach((done) => {
      Vue.http.interceptors.push(response);

      renderNotebook();

      setTimeout(() => {
        done();
      });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, response,
      );
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
