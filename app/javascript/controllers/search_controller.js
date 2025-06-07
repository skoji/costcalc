import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "item"]
  
  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    
    this.itemTargets.forEach(item => {
      const text = item.textContent.toLowerCase()
      if (query === "" || text.includes(query)) {
        item.style.display = "block"
      } else {
        item.style.display = "none"
      }
    })
    
    // Show "no results" message if no items are visible
    this.updateNoResultsMessage()
  }
  
  updateNoResultsMessage() {
    const visibleItems = this.itemTargets.filter(item => item.style.display !== "none")
    const noResultsElement = document.getElementById("no-results-message")
    
    if (visibleItems.length === 0 && this.inputTarget.value.trim() !== "") {
      if (!noResultsElement) {
        const message = document.createElement("div")
        message.id = "no-results-message"
        message.className = "text-center py-12"
        message.innerHTML = '<p class="text-gray-500 text-lg">検索結果が見つかりません。</p>'
        this.element.appendChild(message)
      }
    } else {
      if (noResultsElement) {
        noResultsElement.remove()
      }
    }
  }
  
  clear() {
    this.inputTarget.value = ""
    this.filter()
  }
}