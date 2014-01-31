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
