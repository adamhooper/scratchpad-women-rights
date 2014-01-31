# Maps each Right to a number of points.
#
# Internally, this is an Array of points per right, indexed by Right ID.
class RightScoringFormula
  constructor: (@rightPointsById) ->

  rightIdPoints: (rightId) ->
    @rightPointsById[rightId]

  maxPoints: ->
    sum = 0
    (sum += p) for p in @rightPointsById
    sum

  countryScore: (country) ->
    score = 0
    for hasRight, rightId in country.hasRightById when hasRight
      score += @rightPointsById[rightId]
    score

  # Returns an Array of Arrays of countries. Countries in position 0 have score
  # 0; those in position 1 have score 1, and so on.
  groupCountriesByScore: (countries) ->
    ret = []

    for country in countries
      score = @countryScore(country)
      while score >= ret.length
        ret.push([])
      ret[score].push(country)

    ret

  withRightIdPointed: (rightId, points) ->
    if @rightPointsById[rightId] == points
      this
    else
      newPointsById = @rightPointsById.slice()
      newPointsById[rightId] = points
      new RightScoringFormula(newPointsById)
