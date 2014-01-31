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
