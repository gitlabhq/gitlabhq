var client = algoliasearch('8VO8708WUV', '1f3e2b6f6a503fa82efdec331fd9c55e');
var index = client.initIndex('prod_graphql_ruby');

var GraphQLRubySearch = {
  // Respond to a change event on `el` by:
  // - Searching the index
  // - Rendering the results
  run: function(el) {
    var searchTerm = el.value
    var searchResults = document.querySelector("#search-results")
    if (!searchTerm) {
      // If there's no search term, clear the results pane
      searchResults.innerHTML = ""
    } else {
      index.search({
        query: searchTerm,
        hitsPerPage: 8,
      }, function(err, content) {
        if (err) {
          console.error(err)
        }
        var results = content.hits
        // Clear the previous results
        searchResults.innerHTML = ""

        results.forEach(function(result) {
          // Create a wrapper hyperlink
          var container = document.createElement("a")
          container.className = "search-result"
          container.href = (result.rubydoc_url || result.url) + (result.anchor  ? "#" + result.anchor : "")

          // This helper will be used to accumulate text into the search-result
          function createSpan(text, className) {
            var txt = document.createElement("span")
            txt.className = className
            txt.innerHTML = text
            container.appendChild(txt)
          }
          if (result.rubydoc_url) {
            createSpan("API Doc", "search-category")
            createSpan(result.title, "search-title")
          } else {
            createSpan(result.section, "search-category")

            var resultHeader = [result.title].concat(result.headings).join(" > ")
            createSpan(resultHeader, "search-title")
            var preview = result._snippetResult.content.value
            createSpan(preview, "search-preview")
          }
          searchResults.appendChild(container)
        })

        var seeAll = document.createElement("a")
        seeAll.href = "/search?query=" + content.query
        seeAll.className = "search-see-all"
        seeAll.innerHTML = "See All Results (" + content.nbHits + ")"
        searchResults.appendChild(seeAll)
      })
    }
  },

  // Return true if we actually highlighted something
  _moveHighlight: function(diff) {
    var allResults = document.querySelectorAll(".search-result")
    var highlightClass = "highlight-search-result"
    if (!allResults.length) {
      // No search results to highlight
      return false
    }
    var highlightedResult = document.querySelector("." + highlightClass)
    var nextHighlightedResult
    var result
    for (var i = 0; i < allResults.length; i++) {
      result = allResults[i]
      if (result == highlightedResult) {
        nextHighlightedResult = allResults[i + diff]
        break
      }
    }
    if (!nextHighlightedResult) {
      // Either nothing was highlighted yet,
      // or we were at the end of results and we loop around
      nextHighlightedResult = allResults[0]
    }

    if (highlightedResult) {
      highlightedResult.classList.remove(highlightClass)
    }
    nextHighlightedResult.classList.add(highlightClass)
    nextHighlightedResult.focus()
    return true
  }
}

document.addEventListener("keydown", function(ev) {
  var diff = ev.keyCode == 38 ? -1 : (ev.keyCode == 40 ? 1 : 0)
  if (diff) {
    var highlighted = GraphQLRubySearch._moveHighlight(diff)
    if (highlighted) {
      ev.preventDefault()
    }
  }
})
