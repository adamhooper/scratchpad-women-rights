countries = []

# A Right has an integer ID (first one is 0) and a name.
class Right
  constructor: (@id, @name) ->

# A Country has an ISO-code ID, a name, and rights. Rights are represented
# as an array of booleans, indexed by Right ID.
class Country
  constructor: (@id, @name, @hasRightById) ->

# Stores all rights
class RightCollection
  constructor: (@rights) ->
    @length = @rights.length

# Stores all Countries
class CountryCollection
  constructor: (@countries) ->
    @length = @countries.length
    @_byName = {}
    (@_byName[c.name] = c) for c in @countries

  byName: (name) -> @_byName[name] ? null

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

# Modifies rightScoringFormula
class RightScoringFormulaView
  # Constructor. Pass it these options:
  #
  # el: an HTML element. Must contain three "div.dropbox" elements
  # rightScoringFormula: initial value
  # rightCollection: the RightCollection
  # onChange: will be called whenever rightScoringFormula changes
  constructor: (options) ->
    for key in [ 'el', 'rightScoringFormula', 'rightCollection', 'onChange' ]
      throw "must set #{key}" if !options[key]
      @[key] = options[key]

    @_attach()

  _attach: ->
    @_attachDropbox(dropbox, index) for dropbox, index in $('.dropbox')
    undefined

  _attachDropbox: (el, index) ->
    points = [ 3, 1, 0 ][index]

    $el = $(el)
    $el.on 'dragstart', 'li', (e) ->
      e.originalEvent.dataTransfer.effectAllowed = 'move'
      e.originalEvent.dataTransfer.setData('application/x-women-rights-right-id', e.target.getAttribute('data-right-id'))
    $el.on 'dragover', (e) ->
      e.preventDefault()
    $el.on 'drop', (e) =>
      e.stopPropagation()
      if (data = e.originalEvent.dataTransfer.getData('application/x-women-rights-right-id'))?
        @_onDropRightIdAtPoints(+data, points)

  _onDropRightIdAtPoints: (rightId, points) =>
    newRightScoringFormula = @rightScoringFormula.withRightIdPointed(rightId, points)
    @onChange(newRightScoringFormula)

  # Calculates, for each dropbox, which rights belong inside it.
  #
  # Returns [ [ right1, right2 ], [ right3 ], [right4, right5 ] ]
  _calculateRightsByIndex: ->
    pointsToDropboxIndex = [ 2, 1, null, 0 ]

    indexToRights = ([] for points in pointsToDropboxIndex when points isnt null)

    for right in @rightCollection.rights
      points = @rightScoringFormula.rightIdPoints(right.id)
      index = pointsToDropboxIndex[points]
      indexToRights[index].push(right)

    indexToRights

  render: ->
    $dropboxes = $('.dropbox')

    for rights, index in @_calculateRightsByIndex()
      $dropbox = $($dropboxes.get(index))
      $dropbox.empty()

      lis = ("<li data-right-id='#{right.id}' id='right-#{right.id}' draggable='true'>#{right.name}</li>" for right in rights)

      $dropbox.append("<ul>#{lis.join('')}</ul>")

class ScoredCountriesView
  constructor: (options) ->
    for key in [ 'el', 'rightScoringFormula', 'countryCollection' ]
      throw "must set #{key}" if !options[key]
      @[key] = options[key]

    @$el = $(@el)

  _initialRender: ->
    @$map = $('<div class="map"></div>').appendTo(@$el)

    projection = d3.geo.naturalEarth()

    path = d3.geo.path()
      .projection(projection)

    svg = d3.select(@$map.get(0)).append('svg')
      .attr('width', '100%')
      .attr('height', '100%')

    svg.append('path')
      .datum(type: 'Sphere')
      .attr('class', 'sphere')
      .attr('d', path)

    svg.append('path')
      .datum(d3.geo.graticule())
      .attr('class', 'graticule')
      .attr('d', path)

    countryNameById = d3.map()

    countryIdToPoints = (id) =>
      name = countryNameById.get(id)
      country = @countryCollection.byName(name)
      if country
        @rightScoringFormula.countryScore(country)
      else
        #console.log('Could not find country', id, name)
        0

    ready = (error, world) =>
      countries = topojson.feature(world, world.objects.countries).features

      g = svg.append('g')
        .attr('class', 'countries')

      g.selectAll('path')
        .data(countries)
        .enter().append('path')
          .attr('d', path)

      @_d3.update = =>
        maxPoints = @rightScoringFormula.maxPoints()
        almostMaxPoints = Math.max(maxPoints - 2, 0)

        pointsToClass = (points) ->
          if points == maxPoints
            'q2-3'
          else if points >= almostMaxPoints && almostMaxPoints > 0
            'q1-3'
          else
            'q0-3'

        g.selectAll('path')
          .attr('class', (d) -> 'country ' + pointsToClass(countryIdToPoints(d.id)))

      @_d3.update()

    @_d3 = {}

    queue()
      .defer(d3.json, 'world-50m.json')
      .defer(d3.tsv, 'world-country-names.tsv', (d) -> countryNameById.set(d.id, d.name))
      .await(ready)

  render: ->
    @_initialRender() if !@_d3

    @_d3.update?()

    #@$el.empty()

    #countriesByScore = @rightScoringFormula.groupCountriesByScore(@countryCollection.countries)

    #for countries, score in countriesByScore by -1
    #  @$el.append("<h4>#{countries.length} countries with #{score} points</h4>")
    #  lis = ("<li id='country-#{country.id}'>#{country.name}</li>" for country in countries)
    #  @$el.append("<ul>#{lis.join('')}</ul>")

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

csvRowsToRightsAndCountries = (csvRows) ->
  rightSpecs = [
    {
      column: 'Laws against domestic violence?'
      name: 'Laws against domestic violence'
      test: (s) -> s == 'Yes'
    }
    {
      column: 'Laws against sexual harrassment'
      name: 'Laws against sexual harrassment'
      test: (s) -> s == 'Yes'
    }
    {
      column: 'Year women got right to vote'
      name: 'Women can vote'
      test: (s) -> /\d/.test(s)
    }
    {
      column: 'Year women got right to stand for election'
      name: 'Women can be elected'
      test: (s) -> /\d/.test(s)
    }
    {
      column: 'Year first woman elected (E) or appointed (A) to parliament'
      name: 'Women are in parliament'
      test: (s) -> /\d/.test(s)
    }
  ]

  rights = (new Right(i, spec.name) for spec, i in rightSpecs)

  countries = for row in csvRows
    hasRightById = (spec.test(row[spec.column]) for spec in rightSpecs)
    new Country(row['ISO CODE'], row['COUNTRY'], hasRightById)

  countries.sort((a, b) -> a.name.localeCompare(b.name))

  { rights: new RightCollection(rights), countries: new CountryCollection(countries) }

csvToRows = (csvString) ->
  # http://papaparse.com/docs.html
  parseOutput = $.parse(csvString, dynamicTyping: false)
  if parseOutput.errors?.length
    console.log("Parse errors!", parseOutput.errors)
  results = parseOutput.results
  results.rows

loadRightsAndCountries = ->
  $.ajax('women-rights.csv',
    type: 'GET'
    dataType: 'text'
  )

main = ->
  loadRightsAndCountries()
    .done (csvString) ->
      csvRows = csvToRows(csvString)
      rightsAndCountries = csvRowsToRightsAndCountries(csvRows)
      new App(rightsAndCountries.rights, rightsAndCountries.countries)
    .error -> console.log('Download error:', arguments)

$(main)
