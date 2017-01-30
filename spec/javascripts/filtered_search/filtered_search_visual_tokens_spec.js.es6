require('~/filtered_search/filtered_search_visual_tokens');

(() => {
  describe('Filtered Search Visual Tokens', () => {
    let tokensContainer;

    beforeEach(() => {
      setFixtures(`
        <ul class="tokens-container"></ul>
      `);
      tokensContainer = document.querySelector('.tokens-container');
    });

    afterEach(() => {
      tokensContainer.innerHTML = '';
    });

    describe('getLastVisualToken', () => {
      it('returns when there are no visual tokens', () => {
        const { lastVisualToken, isLastVisualTokenValid }
          = gl.FilteredSearchVisualTokens.getLastVisualToken();

        expect(lastVisualToken).toEqual(undefined);
        expect(isLastVisualTokenValid).toEqual(true);
      });

      it('returns when there is one visual token', () => {
        tokensContainer.innerHTML = `
          <li class="js-visual-token filtered-search-token">
            <div class="name">label</div>
            <div class="value">~bug</div>
          </li>
        `;

        const { lastVisualToken, isLastVisualTokenValid }
          = gl.FilteredSearchVisualTokens.getLastVisualToken();

        expect(lastVisualToken).toEqual(document.querySelector('.filtered-search-token'));
        expect(isLastVisualTokenValid).toEqual(true);
      });

      it('returns when there is an incomplete visual token', () => {
        tokensContainer.innerHTML = `
          <li class="js-visual-token filtered-search-token">
            <div class="name">Author</div>
          </li>
        `;

        const { lastVisualToken, isLastVisualTokenValid }
          = gl.FilteredSearchVisualTokens.getLastVisualToken();

        expect(lastVisualToken).toEqual(document.querySelector('.filtered-search-token'));
        expect(isLastVisualTokenValid).toEqual(false);
      });

      it('returns when there are multiple visual tokens', () => {
        tokensContainer.innerHTML = `
          <li class="js-visual-token filtered-search-token">
            <div class="name">label</div>
            <div class="value">~bug</div>
          </li>
          <li class="js-visual-token filtered-search-term">
            <div class="name">search term</div>
          </li>
          <li class="js-visual-token filtered-search-token">
            <div class="name">author</div>
            <div class="value">@root</div>
          </li>
        `;

        const { lastVisualToken, isLastVisualTokenValid }
          = gl.FilteredSearchVisualTokens.getLastVisualToken();
        const items = document.querySelectorAll('.tokens-container li');

        expect(lastVisualToken).toEqual(items[items.length - 1]);
        expect(isLastVisualTokenValid).toEqual(true);
      });

      it('returns when there are multiple visual tokens and an incomplete visual token', () => {
        tokensContainer.innerHTML = `
          <li class="js-visual-token filtered-search-token">
            <div class="name">label</div>
            <div class="value">~bug</div>
          </li>
          <li class="js-visual-token filtered-search-term">
            <div class="name">search term</div>
          </li>
          <li class="js-visual-token filtered-search-token">
            <div class="name">assignee</div>
          </li>
        `;

        const { lastVisualToken, isLastVisualTokenValid }
          = gl.FilteredSearchVisualTokens.getLastVisualToken();
        const items = document.querySelectorAll('.tokens-container li');

        expect(lastVisualToken).toEqual(items[items.length - 1]);
        expect(isLastVisualTokenValid).toEqual(false);
      });
    });

    describe('addVisualTokenElement', () => {
      it('renders search visual tokens', () => {
        gl.FilteredSearchVisualTokens.addVisualTokenElement('search term', null, true);
        const token = tokensContainer.children[0];

        expect(tokensContainer.children.length).toEqual(1);
        expect(token.classList.contains('js-visual-token')).toEqual(true);
        expect(token.classList.contains('filtered-search-term')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('search term');
        expect(token.querySelector('.value')).toEqual(null);
      });

      it('renders filter visual token name', () => {
        gl.FilteredSearchVisualTokens.addVisualTokenElement('milestone');
        const token = tokensContainer.children[0];

        expect(tokensContainer.children.length).toEqual(1);
        expect(token.classList.contains('js-visual-token')).toEqual(true);
        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('milestone');
        expect(token.querySelector('.value')).toEqual(null);
      });

      it('renders filter visual token name and value', () => {
        gl.FilteredSearchVisualTokens.addVisualTokenElement('label', 'Frontend');
        const token = tokensContainer.children[0];

        expect(tokensContainer.children.length).toEqual(1);
        expect(token.classList.contains('js-visual-token')).toEqual(true);
        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('label');
        expect(token.querySelector('.value').innerText).toEqual('Frontend');
      });
    });

    describe('addFilterVisualToken', () => {
      it('creates visual token with just tokenName', () => {
        gl.FilteredSearchVisualTokens.addFilterVisualToken('milestone');
        const token = tokensContainer.children[0];

        expect(tokensContainer.children.length).toEqual(1);
        expect(token.classList.contains('js-visual-token')).toEqual(true);
        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('milestone');
        expect(token.querySelector('.value')).toEqual(null);
      });

      it('creates visual token with just tokenValue', () => {
        gl.FilteredSearchVisualTokens.addFilterVisualToken('milestone');
        gl.FilteredSearchVisualTokens.addFilterVisualToken('%8.17');
        const token = tokensContainer.children[0];

        expect(tokensContainer.children.length).toEqual(1);
        expect(token.classList.contains('js-visual-token')).toEqual(true);
        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('milestone');
        expect(token.querySelector('.value').innerText).toEqual('%8.17');
      });

      it('creates full visual token', () => {
        gl.FilteredSearchVisualTokens.addFilterVisualToken('assignee', '@john');
        const token = tokensContainer.children[0];

        expect(tokensContainer.children.length).toEqual(1);
        expect(token.classList.contains('js-visual-token')).toEqual(true);
        expect(token.classList.contains('filtered-search-token')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('assignee');
        expect(token.querySelector('.value').innerText).toEqual('@john');
      });
    });

    describe('addSearchVisualToken', () => {
      it('creates search visual token', () => {
        gl.FilteredSearchVisualTokens.addSearchVisualToken('search term');
        const token = tokensContainer.children[0];

        expect(tokensContainer.children.length).toEqual(1);
        expect(token.classList.contains('js-visual-token')).toEqual(true);
        expect(token.classList.contains('filtered-search-term')).toEqual(true);
        expect(token.querySelector('.name').innerText).toEqual('search term');
        expect(token.querySelector('.value')).toEqual(null);
      });
    });
  });
})();
