# A Country has an ISO-code ID, a name, and rights. Rights are represented
# as an array of booleans, indexed by Right ID.
class Country
  constructor: (@id, @name, @hasRightById) ->
