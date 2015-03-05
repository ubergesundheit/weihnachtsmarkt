angular.module("wm-map").controller "MapController", [
  "$scope",
  "leafletData",
  "searchService",
  "staendeService",
  "$timeout"
  ($scope, leafletData, searchService, staendeService, $timeout) ->
    loStyle =
      color: "#f8f8f8"
      weight: 0
      opacity: 1
      fillOpacity: 0.8
    hiStyle =
      color: "#ff3322"
      weight: 1
      opacity: 1
    styleFun = (f) ->
      if f.properties.match
        return hiStyle
      else
        return loStyle
    # highlightFeature = (e) ->
    #   #this.openPopup();
    #   layer = e.target
    #   layer.setStyle hiStyle
    #   return
    # resetHighlight = (e) ->
    #   #this.closePopup();
    #   layer = e.target
    #   layer.setStyle loStyle
    #   return
    # highlightQuery = (e) ->
    #   if searchService._query != ""
    #     content = e.popup.getContent()
    #     # transform the content
    #     content = content.replace RegExp(searchService._query.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"), "gi"), (match) ->
    #         return "<span class='popupHighlight'>#{match}</span>"
    #     , "gi"
    #     e.popup.setContent(content)
    #   return

    markStand = (index) ->
      # $scope.markers
      result = $scope.results[index]
      featureIndex = $scope.geojson.data.features.map((f) -> f.properties.stand_nr).indexOf(result.stand_nr)
      if featureIndex == -1
      feature = $scope.geojson.data.features[featureIndex]
      center = L.GeoJSON.geometryToLayer(feature).getBounds().getCenter()
      $scope.markers.resultMarker.lat = center.lat
      $scope.markers.resultMarker.lng = center.lng
      return
    clickFeature = (e) ->
      # find the appropriate match index
      index = $scope.results.map((r) -> r.stand_nr).indexOf(e.target.feature.properties.stand_nr)
      if index != -1
        $scope.$apply ->
          $scope.currResultIndex = index
          return
      # return
    # set up basic stuff
    angular.extend $scope,
      results: []
      markers:
        resultMarker:
          lat: 0
          lng: 0
          focus: true
          iconUrl: 'http://api.tiles.mapbox.com/v4/marker/pin-s-33+f44@2x.png?access_token=pk.eyJ1IjoidWJlcmdlc3VuZGhlaXQiLCJhIjoiaHhTeV9WcyJ9.jditXHYWvnJegWSfrFGV3w'
      currResultIndex: 0
      muenster:
        lat: 51.96255
        lng: 7.62547
        zoom: 17
      defaults:
        minZoom: 16
        maxZoom: 22
        attributionControl: false
      tiles:
          url: 'http://{s}.tiles.mapbox.com/v3/tomrocket.k93e7pp4/{z}/{x}/{y}.png'
          options:
            maxZoom: 22
      search_query: ''
      geojson:
        style: styleFun
        data: { type: "FeatureCollection", features: [] }
        onEachFeature: (feature, layer) ->
          layer.on
            # mouseover: highlightFeature
            # mouseout: resetHighlight
            # popupopen: highlightQuery
            click: clickFeature

          # feature.on
          #   click: clickFeature

          # popupContent = "#{feature.properties.markt.charAt(0).toUpperCase() + feature.properties.markt.slice(1)} Stand Nr. #{feature.properties.stand_nr}"
          # if feature.properties.warenangeb != null
          #    popupContent = "#{popupContent}<br />#{feature.properties.warenangeb}"
          # if feature.properties.betreiber != null
          #   popupContent = "#{popupContent}<br />#{feature.properties.betreiber}"

          # layer.bindPopup popupContent

          return
      updateGeoJSONFromData: (featureCollection) ->
        # Update the scope
        $scope.geojson =
          style: styleFun
          onEachFeature: $scope.geojson.onEachFeature
          pointToLayer: $scope.geojson.pointToLayer
          data: featureCollection

        # $scope.results = featureCollection.features.filter((f) -> f.properties.match == true ).map((f) -> { heading: f.properties.betreiber, text: f.properties.warenangeb})
        # $scope.currResultIndex = 0

        $timeout ->
          leafletData.getMap('map').then (map) ->
            bounds = L.geoJson($scope.geojson.data).getBounds()
            map.fitBounds(bounds, { maxZoom: 21, padding: [25,25]}) if Object.keys(bounds).length isnt 0
            return
          return
        ,700
        ,false

        return
      setMarktFilter: (markt) ->
        searchService.setFilter { markt: markt }
        return
      findUser: ->
        leafletData.getMap('map').then (map) ->
          map.locate
            watch: true,
            setView: false,
            enableHighAccuracy: true

          map.on "locationfound", (location) ->
            if (!$scope.userMarker)
              $scope.userMarker = L.userMarker(location.latlng, {pulsing:true, accuracy:100, smallIcon:true}).addTo(map)

            $scope.userMarker.setLatLng(location.latlng,)
            $scope.userMarker.setAccuracy(location.accuracy)
            return
          return
        return

    applyQuery = (value, oldvalue, scope) ->
      query = $scope.search_query.trim()
      searchService.setFilter { query: query }
      if $scope.results.length != 0
        markStand($scope.currResultIndex)
      return

    focusInput = (value) ->
      if value == false
        document.getElementById('search_input').focus()
      return

    $scope.$watch 'search_query', applyQuery

    # fetch the data, broadcasts map.updateFeatures event
    staendeService.fetchData()

    $scope.$on 'map.updateFeatures', (evt, data) ->
      $scope.updateGeoJSONFromData(data.featureCollection)
      if data.matches?
        $scope.results = data.matches
        $scope.currResultIndex = 0
        if $scope.results.length != 0
          markStand($scope.currResultIndex)
      return

    $scope.$watch 'currResultIndex', (value) ->
      if $scope.results.length != 0
        markStand(value)
      return

    $scope.bumpResultIndex = (dir) ->
      newIndex = $scope.currResultIndex + dir
      if newIndex >= 0 and newIndex <= $scope.results.length - 1
        $scope.currResultIndex = newIndex
      else if newIndex < 0
        $scope.currResultIndex = $scope.results.length - 1
      else if newIndex > $scope.results.length - 1
        $scope.currResultIndex = 0
      return


    return
]