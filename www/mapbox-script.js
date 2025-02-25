document.addEventListener("DOMContentLoaded", function () {
  // Set the Mapbox Access Token (assumed to be defined in app.R via tags$script)
  mapboxgl.accessToken = mapboxToken;
  
  // Initialize the map using the navigation-day-v1 style, centered on the US,
  // with a zoom level of 3.5 and using the mercator projection.
  const map = new mapboxgl.Map({
    container: "map",
    style: "mapbox://styles/mapbox/navigation-day-v1",
    center: [-95, 40],
    zoom: 3.5,
    projection: { name: "mercator" }
  });
  
  // Set maximum bounds (limits) for the map view (roughly over the US)
  map.setMaxBounds([
    [-130, 5],  // Southwest corner (roughly western and southern border)
    [-60, 60]    // Northeast corner (roughly eastern and northern border)
  ]);
  
  // Add navigation controls to the map
  map.addControl(new mapboxgl.NavigationControl());
  
  // Global variables: store the search popup, hover popup, and currently hovered feature ID
  let searchPopup;
  let hoverPopup = new mapboxgl.Popup({ closeButton: false, closeOnClick: false });
  let hoveredFeatureId = null;
  
  // When the map has finished loading, add the legend and the counties layer
  map.on("load", function () {
    addLegend();
    
    // --- Add mask layer: Cover areas outside the US ---
    // Add a data source for the mask (mask_polygon.geojson located in the www/ directory)
    map.addSource("mask", {
      type: "geojson",
      data: "mask_polygon.geojson"  // Path relative to the www/ folder
    });
    
    // Add the mask layer to cover areas outside the US
    map.addLayer({
      id: "mask-layer",
      type: "fill",
      source: "mask",
      paint: {
        "fill-color": "#ffffff",  // Color to cover areas outside the US (adjust as needed)
        "fill-opacity": 1.0
      }
    });
    
    // Use fetch to load the countiesData.json file
    fetch("countiesData.json")
      .then(response => response.json())
      .then(function(data) {
        // Add a data source and layer for counties
        map.addSource("counties", {
          type: "geojson",
          data: data
        });
        map.addLayer({
          id: "counties-layer",
          type: "fill",
          source: "counties",
          paint: {
            "fill-color": [
              "step",
              ["get", "population"],
              "#d0f3d0", 10000,
              "#a1e9a1", 30000,
              "#99EA85", 50000,
              "#66c456"
            ],
            "fill-opacity": [
              "case",
              ["boolean", ["feature-state", "hover"], false],
              1,
              0.6
            ]
          }
        });
      })
      .catch(function(error) {
        console.error("Error loading countiesData.json:", error);
      });
    
    // Once the map is idle (all layers loaded), make the map container visible
    map.on("idle", function() {
      document.getElementById("map").style.visibility = "visible";
    });
  });
  
  // Function to add a legend to the map container
  function addLegend() {
    const legend = document.createElement("div");
    legend.id = "legend";
    legend.style.position = "absolute";
    legend.style.bottom = "30px";
    legend.style.right = "10px";
    legend.style.backgroundColor = "rgba(255, 255, 255, 0.8)";
    legend.style.padding = "10px";
    legend.style.fontFamily = "Arial, sans-serif";
    legend.style.fontSize = "12px";
    legend.style.boxShadow = "0 0 3px rgba(0,0,0,0.4)";
    legend.innerHTML = '<h4>Population</h4>' +
      '<div><span style="background-color: #d0f3d0; width: 20px; height: 20px; display: inline-block; margin-right: 5px; border-radius: 50%;"></span>&lt; 10,000</div>' +
      '<div><span style="background-color: #a1e9a1; width: 20px; height: 20px; display: inline-block; margin-right: 5px; border-radius: 50%;"></span>10,000 - 30,000</div>' +
      '<div><span style="background-color: #99EA85; width: 20px; height: 20px; display: inline-block; margin-right: 5px; border-radius: 50%;"></span>30,000 - 50,000</div>' +
      '<div><span style="background-color: #66c456; width: 20px; height: 20px; display: inline-block; margin-right: 5px; border-radius: 50%;"></span>&gt; 50,000</div>';
    map.getContainer().appendChild(legend);
  }
  
  // Mouse move event on the counties layer: display county info
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
  
  // Mouse leave event on the counties layer: remove hover popup
  map.on("mouseleave", "counties-layer", function () {
    if (hoveredFeatureId !== null) {
      map.setFeatureState({ source: "counties", id: hoveredFeatureId }, { hover: false });
    }
    hoveredFeatureId = null;
    hoverPopup.remove();
  });
  
  // Shiny message handler for search results: display popup and fly to location
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
  
  // Global function clearMap(), called directly by the Clear button
  window.clearMap = function () {
    if (searchPopup) {
      searchPopup.remove();
      searchPopup = null;
    }
    map.flyTo({ center: [-95, 40], zoom: 3.5 });
  };
});
