angular.module('wm-map').service "searchService",[
  '$rootScope',
  'staendeService',
  ($rootScope, staendeService) ->
    _queryableProperties: [
      'betreiber',
      'warenangeb'
    ]

    setFilter: (filter) ->
      if filter?
        if filter.query?
            @_query = filter.query
        if filter.markt?
            @_markt = filter.markt
        @applyFilter staendeService.getAll().features
      return
    applyFilter: (features) ->
      matches = []
      # hide markets if set..
      if @_markt?
        features = features.filter((f) ->
          f.properties.markt == @_markt
        , @)

      # highlight queries
      if @_query? and @_query.trim() != ""
        regex = RegExp(@_query.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"), 'i')
      else
        regex = /.^/
      features = features.map (f) ->
        f.properties.match = @_queryableProperties.some((q) -> regex.test(f.properties[q]))
        if f.properties.match
          text = ""
          heading = "#{f.properties.markt.charAt(0).toUpperCase() + f.properties.markt.slice(1)} Stand Nr. #{f.properties.stand_nr}"
          if f.properties.warenangeb != null
            text = f.properties.warenangeb
          if f.properties.betreiber != null
            heading = "#{heading}, Betreiber: #{f.properties.betreiber}"
          matches.push({
            stand_nr: f.properties.stand_nr
            heading: heading,
            text: text
          })
        f
      , @ # inject this into map
      $rootScope.$broadcast 'map.updateFeatures',
        featureCollection: { type: "FeatureCollection", features: features },
        matches: matches
      return
]