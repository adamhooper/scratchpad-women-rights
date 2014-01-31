class App
  constructor: (@rightCollection, @countryCollection) ->
    @rightScoringFormula = new RightScoringFormula((0 for right in @rightCollection.rights))

    @_rightScoringFormulaListeners = []

    @_addRightScoringFormulaView()
    @_addScoredCountriesView()

  setRightScoringFormula: (@rightScoringFormula) ->
    for setter in @_rightScoringFormulaListeners
      setter(@rightScoringFormula)

  _addRightScoringFormulaView: ->
    view = new RightScoringFormulaView
      el: $('.right-scoring-formula').get(0)
      rightScoringFormula: @rightScoringFormula
      rightCollection: @rightCollection
      onChange: (rightScoringFormula) => @setRightScoringFormula(rightScoringFormula)
    view.render()

    @_rightScoringFormulaListeners.push (rsf) ->
      view.rightScoringFormula = rsf
      view.render()

  _addScoredCountriesView: ->
    view = new ScoredCountriesView
      el: $('.scored-countries').get(0)
      rightScoringFormula: @rightScoringFormula
      countryCollection: @countryCollection
    view.render()

    @_rightScoringFormulaListeners.push (rsf) ->
      view.rightScoringFormula = rsf
      view.render()
