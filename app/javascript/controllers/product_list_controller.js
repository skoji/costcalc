import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Check if there's an anchor in the URL and scroll to it
    this.scrollToAnchor()
  }
  
  scrollToAnchor() {
    // Get the anchor from the current URL
    const hash = window.location.hash
    
    if (hash) {
      // Wait a moment for the page to fully load
      setTimeout(() => {
        const targetElement = document.querySelector(hash)
        
        if (targetElement) {
          // Scroll to the element with some offset for better visibility
          const elementPosition = targetElement.getBoundingClientRect().top + window.pageYOffset
          const offsetPosition = elementPosition - 100 // 100px offset from top
          
          window.scrollTo({
            top: offsetPosition,
            behavior: 'smooth'
          })
          
          // Add a subtle highlight effect
          this.highlightElement(targetElement)
        }
      }, 100)
    }
  }
  
  highlightElement(element) {
    // Add a temporary highlight class
    element.classList.add('ring-2', 'ring-blue-500', 'ring-opacity-50')
    
    // Remove the highlight after 2 seconds
    setTimeout(() => {
      element.classList.remove('ring-2', 'ring-blue-500', 'ring-opacity-50')
    }, 2000)
  }
}