import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["ingredientsContainer", "ingredientTemplate"]
  static values = { units: Array }
  
  connect() {
    // Count existing ingredient rows and set next index
    const existingRows = this.ingredientsContainerTarget.querySelectorAll('.ingredient-row')
    this.nextIndex = existingRows.length
    
    // Initialize existing search inputs
    this.initializeSearchInputs()
  }
  
  initializeSearchInputs() {
    const searchInputs = this.element.querySelectorAll('.material-search-input')
    searchInputs.forEach(input => {
      this.setupSearchInput(input)
    })
  }
  
  setupSearchInput(input) {
    const row = input.closest('.ingredient-row')
    const materialIdInput = row.querySelector('.material-id-input')
    const unitSelect = row.querySelector('.unit-select')
    const dataListId = input.getAttribute('list')
    
    // Handle selection/input change
    input.addEventListener('change', (e) => {
      this.handleMaterialSelection(input, materialIdInput, unitSelect, dataListId)
    })
    
    input.addEventListener('input', (e) => {
      this.handleMaterialSelection(input, materialIdInput, unitSelect, dataListId)
    })
  }
  
  handleMaterialSelection(input, materialIdInput, unitSelect, dataListId) {
    const dataList = document.getElementById(dataListId)
    if (!dataList) return
    
    // Find matching option in datalist
    const options = dataList.querySelectorAll('option')
    let matchedOption = null
    
    for (const option of options) {
      if (option.value === input.value) {
        matchedOption = option
        break
      }
    }
    
    if (matchedOption) {
      // Set material ID and update units
      materialIdInput.value = matchedOption.dataset.id
      const unitIds = matchedOption.dataset.unitIds ? 
        matchedOption.dataset.unitIds.split(',').map(id => parseInt(id)) : []
      this.updateUnitOptions(unitSelect, unitIds)
    } else {
      // Clear material ID and units if no match
      materialIdInput.value = ''
      this.updateUnitOptions(unitSelect, [])
    }
  }
  
  updateUnitOptions(unitSelect, unitIds) {
    const currentValue = unitSelect.value
    
    // Clear existing options
    unitSelect.innerHTML = '<option value="">単位を選択</option>'
    
    // Add unit options for this material
    unitIds.forEach(unitId => {
      const unit = this.unitsValue.find(u => u.id === unitId)
      if (unit) {
        const option = document.createElement('option')
        option.value = unit.id
        option.text = unit.name
        if (currentValue == unit.id) {
          option.selected = true
        }
        unitSelect.appendChild(option)
      }
    })
  }
  
  addIngredient(event) {
    event.preventDefault()
    
    const template = this.ingredientTemplateTarget.innerHTML
      .replace(/__INDEX__/g, this.nextIndex)
      .replace(/disabled="disabled"/g, '')
    
    this.ingredientsContainerTarget.insertAdjacentHTML('beforeend', template)
    
    // Initialize the new search input
    const newRow = this.ingredientsContainerTarget.lastElementChild
    const searchInput = newRow.querySelector('.material-search-input')
    if (searchInput) {
      this.setupSearchInput(searchInput)
    }
    
    // Auto-scroll to the new ingredient row
    this.scrollToNewIngredient(newRow)
    
    this.nextIndex++
  }
  
  scrollToNewIngredient(newRow) {
    // Wait a moment for the DOM to update
    setTimeout(() => {
      // Check if the new row is visible in the viewport
      const rowRect = newRow.getBoundingClientRect()
      const viewportHeight = window.innerHeight
      
      // If the bottom of the row is below the viewport, scroll to it
      if (rowRect.bottom > viewportHeight - 100) { // 100px margin for better UX
        newRow.scrollIntoView({ 
          behavior: 'smooth', 
          block: 'center' 
        })
      }
      
      // Focus on the material search input for immediate use
      const searchInput = newRow.querySelector('.material-search-input')
      if (searchInput) {
        searchInput.focus()
      }
    }, 100)
  }
  
  removeIngredient(event) {
    event.preventDefault()
    
    const row = event.target.closest('.ingredient-row')
    const destroyInput = row.querySelector('.destroy-input')
    
    if (destroyInput) {
      // Mark for destruction
      destroyInput.value = '1'
      row.style.display = 'none'
    } else {
      // Remove new row completely
      row.remove()
    }
  }
}