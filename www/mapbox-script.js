document.addEventListener("DOMContentLoaded", function () {
  // Setting the Mapbox Access Token
  mapboxgl.accessToken = mapboxToken;
  
  // Initialize the map with center position set to [-95, 40] and zoom level 3.5
  const map = new mapboxgl.Map({
    container: "map",
    style: "mapbox://styles/mapbox/streets-v11",
    center: [-95, 40],
    zoom: 3.5
  });
  
  map.addControl(new mapboxgl.NavigationControl());
  
  // Global variable: Used to store popups created after a search and popups used on mouse hover.
  var searchPopup;  
  let hoverPopup = new mapboxgl.Popup({ closeButton: false, closeOnClick: false });
  let hoveredFeatureId = null;
  
  // Processing counties GeoJSON data sent from the backend
  Shiny.addCustomMessageHandler("updateCounties", function (geojsonData) {
    console.log("Received GeoJSON data:", geojsonData);
    
    if (map.getSource("counties")) {
      map.getSource("counties").setData(geojsonData);
    } else {
      map.addSource("counties", {
        type: "geojson",
        data: geojsonData
      });
      map.addLayer({
        id: "counties-layer",
        type: "fill",
        source: "counties",
        paint: {
          "fill-color": [
            "step",
            ["get", "population"],
            "#fff5f0", 10000,
            "#fcbba1", 30000,
            "#fb6a4a", 50000,
            "#cb181d"
          ],
          "fill-opacity": [
            "case",
            ["boolean", ["feature-state", "hover"], false],
            1,
            0.6
          ]
        }
      });
    }
    
    // Hover: displays county name and population information
    map.on("mousemove", "counties-layer", function (e) {
      if (e.features.length > 0) {
        if (hoveredFeatureId !== null) {
          map.setFeatureState({ source: "counties", id: hoveredFeatureId }, { hover: false });
        }
        hoveredFeatureId = e.features[0].id;
        map.setFeatureState({ source: "counties", id: hoveredFeatureId }, { hover: true });
        
        const properties = e.features[0].properties;
        hoverPopup
          .setLngLat(e.lngLat)
          .setHTML("<strong>County:</strong> " + properties.county_name + "<br><strong>Population:</strong> " + properties.population)
          .addTo(map);
      }
    });
    
    map.on("mouseleave", "counties-layer", function () {
      if (hoveredFeatureId !== null) {
        map.setFeatureState({ source: "counties", id: hoveredFeatureId }, { hover: false });
      }
      hoveredFeatureId = null;
      hoverPopup.remove();
    });
  });
  
  // Handle search result messages: show popup and fly to corresponding position
  Shiny.addCustomMessageHandler("updateSearch", function (coords) {
    if (searchPopup) {
      searchPopup.remove();
    }
    searchPopup = new mapboxgl.Popup()
      .setLngLat([coords.lng, coords.lat])
      .setHTML(coords.popup)
      .addTo(map);
    map.flyTo({ center: [coords.lng, coords.lat], zoom: 8 });
  });
  
  // Define a global function clearMap() to be called directly by the Clear button.
  window.clearMap = function () {
    console.log("clearMap() called");
    if (searchPopup) {
      searchPopup.remove();
      searchPopup = null;
    }
    map.flyTo({ center: [-95, 40], zoom: 3.5 });
  };
});
