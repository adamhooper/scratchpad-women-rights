csvRowsToRightsAndCountries = (csvRows) ->
  rightSpecs = [
    {
      column: 'Laws against domestic violence?'
      name: 'Laws protecting you from domestic violence'
      test: (s) -> s == 'Yes'
    }
    {
      column: 'Laws against sexual harrassment'
      name: 'Laws protecting you from sexual harrassment'
      test: (s) -> s == 'Yes'
    }
    {
      column: 'Year women got right to vote'
      name: 'The right to vote'
      test: (s) -> /\d/.test(s)
    }
    {
      column: 'Year women got right to stand for election'
      name: 'The right to run for parliament'
      test: (s) -> /\d/.test(s)
    }
    {
      column: 'Year first woman elected (E) or appointed (A) to parliament'
      name: 'People of your gender in parliament'
      test: (s) -> /\d/.test(s)
    }
  ]

  rights = (new Right(i, spec.name) for spec, i in rightSpecs)

  countries = for row in csvRows
    hasRightById = for spec in rightSpecs
      spec.test(row[spec.column])
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
