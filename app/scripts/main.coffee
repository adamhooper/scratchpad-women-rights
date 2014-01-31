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
