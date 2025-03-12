function detectTheme() {
  var storedTheme = localStorage.getItem("graphql_dashboard:theme")
  var preferredTheme = !!window.matchMedia('(prefers-color-scheme: dark)').matches ? "dark" : "light"
  setTheme(storedTheme || preferredTheme)
}

function toggleTheme() {
  var nextTheme = document.documentElement.getAttribute("data-bs-theme") == "dark" ? "light" : "dark"
  setTheme(nextTheme)
}

function setTheme(theme) {
  localStorage.setItem("graphql_dashboard:theme", theme)
  document.documentElement.setAttribute("data-bs-theme", theme)
  var icon = theme == "dark" ? "🌙" : "🌞"
  var toggle = document.getElementById("themeToggle")
  if (toggle) {
    toggle.innerText = icon
  } else {
    document.addEventListener("DOMContentLoaded", function(_ev) {
      document.getElementById("themeToggle").innerText = icon
    })
  }
}

detectTheme()

var perfettoUrl = "https://ui.perfetto.dev"
async function openOnPerfetto(operationName, tracePath) {
  var resp = await fetch(tracePath);
  var blob = await resp.blob();
  var nextPerfettoData = await blob.arrayBuffer();
  nextPerfettoWindow = window.open(perfettoUrl)

  var messageHandler = function(event) {
    if (event.origin == perfettoUrl && event.data == "PONG") {
      clearInterval(perfettoWaiting)
      window.removeEventListener("message", messageHandler)
      nextPerfettoWindow.postMessage({
        perfetto: {
          buffer: nextPerfettoData,
          title: operationName + " - GraphQL",
          filename: "perfetto-" + operationName + ".dump",
        }
      }, perfettoUrl)
    }
  }

  window.addEventListener("message", messageHandler, false)
  perfettoWaiting = setInterval(function() {
    nextPerfettoWindow.postMessage("PING", perfettoUrl)
  }, 100)
}

async function deleteTrace(tracePath, event) {
  if (confirm("Are you sure you want to permanently delete this trace?")) {
    var response = await fetch(tracePath, { method: "DELETE", headers: {
      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
    } })
    if (response.ok) {
      var row = event.target.closest("tr")
      row.remove()
    } else {
      console.error("Delete request failed for", tracePath, response)
    }
  }
}

document.addEventListener("click", function(event) {
  var dataset = event.target.dataset
  if (dataset.perfettoOpen) {
    openOnPerfetto(dataset.perfettoOpen, dataset.perfettoPath)
  } else if (dataset.perfettoDelete) {
    deleteTrace(dataset.perfettoDelete, event)
  } else if (event.target.id == "themeToggle") {
    toggleTheme()
  }
})
