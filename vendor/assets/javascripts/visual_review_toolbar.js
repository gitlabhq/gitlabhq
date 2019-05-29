///////////////////////////////////////////////
/////////////////// STYLES ////////////////////
///////////////////////////////////////////////

// this style must be applied inline
const buttonClearStyles = `
  -webkit-appearance: none;
`;

///////////////////////////////////////////////
/////////////////// STATE ////////////////////
///////////////////////////////////////////////
const data = {};

///////////////////////////////////////////////
///////////////// COMPONENTS //////////////////
///////////////////////////////////////////////
const note = `
  <p id='gitlab-validation-note' class='gitlab-message'></p>
`;

const comment = `
  <div>
    <textarea id='gitlab-comment' name='gitlab-comment' rows='3' placeholder='Enter your feedback or idea' class='gitlab-input'></textarea>
    ${note}
    <p class='gitlab-metadata-note'>Additional metadata will be included: browser, OS, current page, user agent, and viewport dimensions.</p>
  </div>
  <div class='gitlab-button-wrapper''>
    <button class='gitlab-button gitlab-button-secondary' style='${buttonClearStyles}' type='button' id='gitlab-logout-button'> Logout </button>
    <button class='gitlab-button gitlab-button-success' style='${buttonClearStyles}' type='button' id='gitlab-comment-button'> Send feedback </button>
  </div>
`;

const commentIcon = `
  <svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><title>icn/comment</title><path d="M4 11.132l1.446-.964A1 1 0 0 1 6 10h5a1 1 0 0 0 1-1V5a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v6.132zM6.303 12l-2.748 1.832A1 1 0 0 1 2 13V5a3 3 0 0 1 3-3h6a3 3 0 0 1 3 3v4a3 3 0 0 1-3 3H6.303z" id="gitlab-comment-icon"/></svg>
`;

const compressIcon = `
  <svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><title>icn/compress</title><path d="M5.27 12.182l-1.562 1.561a1 1 0 0 1-1.414 0h-.001a1 1 0 0 1 0-1.415l1.56-1.56L2.44 9.353a.5.5 0 0 1 .353-.854H7.09a.5.5 0 0 1 .5.5v4.294a.5.5 0 0 1-.853.353l-1.467-1.465zm6.911-6.914l1.464 1.464a.5.5 0 0 1-.353.854H8.999a.5.5 0 0 1-.5-.5V2.793a.5.5 0 0 1 .854-.354l1.414 1.415 1.56-1.561a1 1 0 1 1 1.415 1.414l-1.561 1.56z" id="gitlab-compress-icon"/></svg>
`;

const collapseButton = `
  <button id='gitlab-collapse' style='${buttonClearStyles}' class='gitlab-button gitlab-button-secondary gitlab-collapse gitlab-collapse-open'>${compressIcon}</button>
`;

const form = content => `
  <div id='gitlab-form-wrapper'>
    ${content}
  </div>
`;

const login = `
  <div>
    <label for='gitlab-token' class='gitlab-label'>Enter your <a class='gitlab-link' href="https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html">personal access token</a></label>
    <input class='gitlab-input' type='password' id='gitlab-token' name='gitlab-token'>
    ${note}
  </div>
  <div class='gitlab-checkbox-wrapper'>
    <input type="checkbox" id="remember_token" name="remember_token" value="remember">
    <label for="remember_token" class='gitlab-checkbox-label'>Remember me</label>
  </div>
  <div class='gitlab-button-wrapper'>
    <button class='gitlab-button-wide gitlab-button gitlab-button-success' style='${buttonClearStyles}' type='button' id='gitlab-login'> Submit </button>
  </div>
`;

///////////////////////////////////////////////
//////////////// INTERACTIONS /////////////////
///////////////////////////////////////////////

// from https://developer.mozilla.org/en-US/docs/Web/API/Window/navigator
function getBrowserId(sUsrAg) {
  var aKeys = ['MSIE', 'Edge', 'Firefox', 'Safari', 'Chrome', 'Opera'],
    nIdx = aKeys.length - 1;

  for (nIdx; nIdx > -1 && sUsrAg.indexOf(aKeys[nIdx]) === -1; nIdx--);
  return aKeys[nIdx];
}

function addCommentForm() {
  const formWrapper = document.getElementById('gitlab-form-wrapper');
  formWrapper.innerHTML = comment;
}

function addLoginForm() {
  const formWrapper = document.getElementById('gitlab-form-wrapper');
  formWrapper.innerHTML = login;
}

function authorizeUser() {
  // Clear any old errors
  clearNote('gitlab-token');

  const token = document.getElementById('gitlab-token').value;
  const rememberMe = document.getElementById('remember_token').checked;

  if (!token) {
    postError('Please enter your token.', 'gitlab-token');
    return;
  }

  if (rememberMe) {
    storeToken(token);
  }

  authSuccess(token);
  return;
}

function authSuccess(token) {
  data.token = token;
  addCommentForm();
}

function clearNote(inputId) {
  const note = document.getElementById('gitlab-validation-note');
  note.innerText = '';
  note.style.color = '';

  if (inputId) {
    const field = document.getElementById(inputId);
    field.style.borderColor = '';
  }
}

function confirmAndClear(mergeRequestId) {
  const commentButton = document.getElementById('gitlab-comment-button');
  const note = document.getElementById('gitlab-validation-note');

  commentButton.innerText = 'Feedback sent';
  note.innerText = `Your comment was successfully posted to merge request #${mergeRequestId}`;

  setTimeout(resetCommentButton, 1000);
}

function getInitialState() {
  const { localStorage } = window;

  try {
    let token = localStorage.getItem('token');

    if (token) {
      data.token = token;
      return comment;
    }

    return login;
  } catch (err) {
    return login;
  }
}

function getProjectDetails() {
  const {
    innerWidth,
    innerHeight,
    location: { href },
    navigator: { platform, userAgent },
  } = window;
  const browser = getBrowserId(userAgent);

  const scriptEl = document.getElementById('review-app-toolbar-script');
  const { projectId, mergeRequestId, mrUrl } = scriptEl.dataset;

  return {
    href,
    platform,
    browser,
    userAgent,
    innerWidth,
    innerHeight,
    projectId,
    mergeRequestId,
    mrUrl,
  };
}

function logoutUser() {
  const { localStorage } = window;

  // All the browsers we support have localStorage, so let's silently fail
  // and go on with the rest of the functionality.
  try {
    localStorage.removeItem('token');
  } catch (err) {
    return;
  }

  addLoginForm();
}

function postComment({
  href,
  platform,
  browser,
  userAgent,
  innerWidth,
  innerHeight,
  projectId,
  mergeRequestId,
  mrUrl,
}) {
  // Clear any old errors
  clearNote('gitlab-comment');

  setInProgressState();

  const commentText = document.getElementById('gitlab-comment').value.trim();

  if (!commentText) {
    postError('Your comment appears to be empty.', 'gitlab-comment');
    resetCommentBox();
    return;
  }

  const detailText = `
 \n
<details>
  <summary>Metadata</summary>
  Posted from ${href} | ${platform} | ${browser} | ${innerWidth} x ${innerHeight}.
  <br /><br />
  <em>User agent: ${userAgent}</em>
</details>
  `;

  const url = `
    ${mrUrl}/api/v4/projects/${projectId}/merge_requests/${mergeRequestId}/discussions`;

  const body = `${commentText} ${detailText}`;

  fetch(url, {
    method: 'POST',
    headers: {
      'PRIVATE-TOKEN': data.token,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ body }),
  })
    .then(response => {
      if (response.ok) {
        confirmAndClear(mergeRequestId);
        return;
      }

      throw new Error(`${response.status}: ${response.statusText}`);
    })
    .catch(err => {
      postError(
        `The feedback was not sent successfully. Please try again. Error: ${err.message}`,
        'gitlab-comment',
      );
      resetCommentBox();
    });
}

function postError(message, inputId) {
  const note = document.getElementById('gitlab-validation-note');
  const field = document.getElementById(inputId);
  field.style.borderColor = '#db3b21';
  note.style.color = '#db3b21';
  note.innerText = message;
}

function resetCommentBox() {
  const commentBox = document.getElementById('gitlab-comment');
  const commentButton = document.getElementById('gitlab-comment-button');

  commentButton.innerText = 'Send feedback';
  commentButton.classList.replace('gitlab-button-secondary', 'gitlab-button-success');
  commentButton.style.opacity = 1;

  commentBox.style.pointerEvents = 'auto';
  commentBox.style.color = 'rgba(0, 0, 0, 1)';
}

function resetCommentButton() {
  const commentBox = document.getElementById('gitlab-comment');
  const note = document.getElementById('gitlab-validation-note');

  commentBox.value = '';
  note.innerText = '';
  resetCommentBox();
}

function setInProgressState() {
  const commentButton = document.getElementById('gitlab-comment-button');
  const commentBox = document.getElementById('gitlab-comment');

  commentButton.innerText = 'Sending feedback';
  commentButton.classList.replace('gitlab-button-success', 'gitlab-button-secondary');
  commentButton.style.opacity = 0.5;
  commentBox.style.color = 'rgba(223, 223, 223, 0.5)';
  commentBox.style.pointerEvents = 'none';
}

function storeToken(token) {
  const { localStorage } = window;

  // All the browsers we support have localStorage, so let's silently fail
  // and go on with the rest of the functionality.
  try {
    localStorage.setItem('token', token);
  } catch (err) {
    return;
  }
}

function toggleForm() {
  const container = document.getElementById('gitlab-review-container');
  const collapseButton = document.getElementById('gitlab-collapse');
  const form = document.getElementById('gitlab-form-wrapper');
  const OPEN = 'open';
  const CLOSED = 'closed';

  const stateVals = {
    [OPEN]: {
      buttonClasses: ['gitlab-collapse-closed', 'gitlab-collapse-open'],
      containerClasses: ['gitlab-closed-wrapper', 'gitlab-open-wrapper'],
      icon: compressIcon,
      display: 'flex',
      backgroundColor: 'rgba(255, 255, 255, 1)',
    },
    [CLOSED]: {
      buttonClasses: ['gitlab-collapse-open', 'gitlab-collapse-closed'],
      containerClasses: ['gitlab-open-wrapper', 'gitlab-closed-wrapper'],
      icon: commentIcon,
      display: 'none',
      backgroundColor: 'rgba(255, 255, 255, 0)',
    },
  };

  const nextState = collapseButton.classList.contains('gitlab-collapse-open') ? CLOSED : OPEN;

  container.classList.replace(...stateVals[nextState].containerClasses);
  container.style.backgroundColor = stateVals[nextState].backgroundColor;
  form.style.display = stateVals[nextState].display;
  collapseButton.classList.replace(...stateVals[nextState].buttonClasses);
  collapseButton.innerHTML = stateVals[nextState].icon;
}

///////////////////////////////////////////////
///////////////// INJECTION //////////////////
///////////////////////////////////////////////

function noop() {}

const eventLookup = ({ target: { id } }) => {
  switch (id) {
    case 'gitlab-collapse':
      return toggleForm;
    case 'gitlab-comment-button':
      const projectDetails = getProjectDetails();
      return postComment.bind(null, projectDetails);
    case 'gitlab-login':
      return authorizeUser;
    case 'gitlab-logout-button':
      return logoutUser;
    default:
      return noop;
  }
};

window.addEventListener('load', () => {
  const content = getInitialState();
  const container = document.createElement('div');

  container.setAttribute('id', 'gitlab-review-container');
  container.insertAdjacentHTML('beforeend', collapseButton);
  container.insertAdjacentHTML('beforeend', form(content));

  document.body.insertBefore(container, document.body.firstChild);

  document.getElementById('gitlab-review-container').addEventListener('click', event => {
    eventLookup(event)();
  });
  
});
