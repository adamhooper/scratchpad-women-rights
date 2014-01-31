class CountryCollection
  constructor: (@countries) ->
    @length = @countries.length
    @_byName = {}
    (@_byName[c.name] = c) for c in @countries

  byName: (name) -> @_byName[name] ? null
